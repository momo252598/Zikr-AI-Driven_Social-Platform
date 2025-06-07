import os
import uuid
import random
from django.conf import settings
from supabase import create_client, Client
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.db.models import Count, Q, Case, When, IntegerField, Value, F
from django.db.models.functions import Coalesce

from .models import Post, Comment, Like, MediaPost, Tag
from .serializers import PostSerializer, CommentSerializer, MediaPostSerializer, TagSerializer

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.annotate(
        comments_count=Count('comments', distinct=True),
        likes_count=Count('likes', distinct=True)
    )
    serializer_class = PostSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
    
    def perform_destroy(self, instance):
        """
        Override to ensure proper cascading delete
        """
        # Check if user has permission to delete the post
        if instance.author != self.request.user:
            raise permissions.PermissionDenied("You can only delete your own posts.")
        
        # The cascade delete is handled by the database due to on_delete=models.CASCADE
        # All related MediaPost, Comment, Like, and SavedPost objects will be deleted automatically
        instance.delete()
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
        
    def get_queryset(self):
        # Filter by visibility based on relationship with the author
        user = self.request.user
        queryset = Post.objects.filter(
            Q(visibility='public') |
            Q(author=user) |
            (Q(visibility='followers') & Q(author__followers=user))
        ).annotate(
            comments_count=Count('comments', distinct=True),
            likes_count=Count('likes', distinct=True)
        )
        
        # Filter by tags if specified in query parameters
        tags = self.request.query_params.getlist('tag')
        if tags:
            queryset = queryset.filter(tags__id__in=tags).distinct()
              # Filter by category if specified
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(tags__category=category).distinct()
            
        # Filter by author if specified (for profile pages)
        author_id = self.request.query_params.get('author')
        if author_id:
            try:
                author_id_int = int(author_id)
                queryset = queryset.filter(author__id=author_id_int)
                # Return chronological order for profile pages, no suggestion algorithm
                return queryset.order_by('-created_at')
            except (ValueError, TypeError):
                pass  # Ignore invalid author_id
        
        # Check for time-based ordering parameter
        ordering = self.request.query_params.get('ordering')
        if ordering == 'latest':
            # Return posts ordered by creation time (latest first) with pagination
            return queryset.order_by('-created_at')
            
        # If no specific filters are applied (الكل filter), apply suggestion algorithm
        if not tags and not category and not author_id and ordering != 'latest':
            return self._apply_suggestion_algorithm(queryset)
            
        return queryset.order_by('-created_at')
    
    def _apply_suggestion_algorithm(self, queryset):
        """
        Apply the suggestion algorithm for the "الكل" (All) filter.
        This algorithm combines user preferences, global popularity, and diversity.
        """
        user = self.request.user
        
        # Step 1: Calculate user's tag preferences based on their likes
        user_tag_weights = self._calculate_user_tag_weights(user)
        
        # Step 2: Calculate global tag popularity
        global_tag_weights = self._calculate_global_tag_weights()
        
        # Step 3: Combine user preferences with global popularity
        combined_weights = self._combine_weights(user_tag_weights, global_tag_weights)
        
        # Step 4: Apply diversity and create weighted post ordering
        return self._create_diverse_post_ordering(queryset, combined_weights)
    
    def _calculate_user_tag_weights(self, user):
        """
        Calculate weights for tags based on user's like history.
        Returns a dictionary of tag_id -> weight.
        """
        # Get all tags the user has liked posts for
        user_liked_tags = Tag.objects.filter(
            posts__likes__user=user
        ).annotate(
            user_likes_count=Count('posts__likes', filter=Q(posts__likes__user=user))
        ).values('id', 'user_likes_count')
        
        # Create weight dictionary
        weights = {}
        for tag_data in user_liked_tags:
            tag_id = tag_data['id']
            likes_count = tag_data['user_likes_count']
            # Weight proportional to likes, with minimum weight of 1
            weights[tag_id] = max(likes_count, 1)
        
        # Get all tags to ensure every tag has a weight
        all_tags = Tag.objects.values_list('id', flat=True)
        for tag_id in all_tags:
            if tag_id not in weights:
                # Small fixed weight for tags the user hasn't liked
                weights[tag_id] = 0.1
        
        return weights
    
    def _calculate_global_tag_weights(self):
        """
        Calculate global popularity weights for tags based on overall likes.
        Returns a dictionary of tag_id -> weight.
        """
        global_tag_data = Tag.objects.annotate(
            global_likes_count=Count('posts__likes')
        ).values('id', 'global_likes_count')
        
        weights = {}
        max_global_likes = 1  # Avoid division by zero
        
        # Find maximum likes for normalization
        for tag_data in global_tag_data:
            max_global_likes = max(max_global_likes, tag_data['global_likes_count'])
        
        # Calculate normalized weights
        for tag_data in global_tag_data:
            tag_id = tag_data['id']
            likes_count = tag_data['global_likes_count']
            # Normalize to 0-1 range and add small base weight
            normalized_weight = (likes_count / max_global_likes) * 0.5 + 0.1
            weights[tag_id] = normalized_weight
        
        return weights
    
    def _combine_weights(self, user_weights, global_weights):
        """
        Combine user preferences with global popularity.
        User preferences get 70% weight, global popularity gets 30%.
        """
        combined = {}
        all_tag_ids = set(user_weights.keys()) | set(global_weights.keys())
        
        for tag_id in all_tag_ids:
            user_weight = user_weights.get(tag_id, 0.1)
            global_weight = global_weights.get(tag_id, 0.1)
            
            # Combine with 70% user preference, 30% global popularity
            combined[tag_id] = (user_weight * 0.7) + (global_weight * 0.3)
        
        return combined
    
    def _create_diverse_post_ordering(self, queryset, tag_weights):
        """
        Create a diverse ordering of posts based on tag weights while maintaining diversity.
        """
        # Get posts with their tags and calculate post scores
        posts_with_scores = []
        
        for post in queryset.prefetch_related('tags'):
            post_tags = post.tags.all()
            
            if post_tags:
                # Calculate post score as average of its tags' weights
                tag_scores = [tag_weights.get(tag.id, 0.1) for tag in post_tags]
                post_score = sum(tag_scores) / len(tag_scores)
            else:
                # Posts without tags get a small score
                post_score = 0.1
            
            # Add some randomness for diversity (±20% variation)
            randomness_factor = random.uniform(0.8, 1.2)
            final_score = post_score * randomness_factor
            
            posts_with_scores.append((post.id, final_score))
        
        # Sort posts by score (descending) but implement diversity mechanism
        posts_with_scores.sort(key=lambda x: x[1], reverse=True)
        
        # Apply diversity mechanism: every 4th post should be from lower-weighted tags
        diversified_order = []
        high_score_posts = []
        low_score_posts = []
        
        # Separate posts into high and low score groups
        median_score = sorted([score for _, score in posts_with_scores])[len(posts_with_scores) // 2] if posts_with_scores else 0
        
        for post_id, score in posts_with_scores:
            if score >= median_score:
                high_score_posts.append(post_id)
            else:
                low_score_posts.append(post_id)
        
        # Create diversified ordering: 3 high-score posts, then 1 low-score post
        high_idx = 0
        low_idx = 0
        position = 0
        
        while high_idx < len(high_score_posts) or low_idx < len(low_score_posts):
            # Every 4th position (0, 4, 8, ...) gets a low-score post for diversity
            if position % 4 == 3 and low_idx < len(low_score_posts):
                diversified_order.append(low_score_posts[low_idx])
                low_idx += 1
            elif high_idx < len(high_score_posts):
                diversified_order.append(high_score_posts[high_idx])
                high_idx += 1
            elif low_idx < len(low_score_posts):
                # If no more high-score posts, use low-score posts
                diversified_order.append(low_score_posts[low_idx])
                low_idx += 1
            
            position += 1
        
        # Create a Case/When expression to order posts according to our diversified order
        if diversified_order:
            ordering_cases = [
                When(id=post_id, then=Value(index))
                for index, post_id in enumerate(diversified_order)
            ]
            
            return queryset.annotate(
                custom_order=Case(
                    *ordering_cases,
                    default=Value(len(diversified_order)),
                    output_field=IntegerField()
                )
            ).order_by('custom_order')
        
        # Fallback to date ordering if no posts found
        return queryset.order_by('-created_at')
    
    @action(detail=True, methods=['POST'])
    def like(self, request, pk=None):
        post = self.get_object()
        like, created = Like.objects.get_or_create(
            user=request.user,
            post=post,
            defaults={'comment': None}
        )
        
        if not created:
            # User already liked this post, so unlike it
            like.delete()
            return Response({'status': 'unliked'})
        
        return Response({'status': 'liked'})
    
    @action(detail=True, methods=['POST'], parser_classes=[MultiPartParser, FormParser])
    def add_media(self, request, pk=None):
        """
        Upload media file for a post and store it in Supabase
        """
        try:
            # Get the post object
            post = self.get_object()
            
            # Get the file from request
            file_obj = request.FILES.get('file')
            if not file_obj:
                return Response({'error': 'No file provided'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Get file type from request or infer from content type
            file_type = request.data.get('file_type', 'image')
            
            # Create a unique filename with original extension
            original_name = file_obj.name
            extension = os.path.splitext(original_name)[1].lower()
            unique_filename = f"{uuid.uuid4()}{extension}"
            
            # Get file content
            file_content = file_obj.read()
            
            # Initialize Supabase client
            supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
            
            # Upload to Supabase
            supabase.storage.from_(settings.SUPABASE_BUCKET).upload(
                unique_filename,
                file_content,
                file_options={"contentType": file_obj.content_type}
            )
            
            # Get the public URL
            file_url = supabase.storage.from_(settings.SUPABASE_BUCKET).get_public_url(unique_filename)
            
            # Create MediaPost object
            media_post = MediaPost.objects.create(
                post=post,
                file_url=file_url,
                file_type=file_type
            )
            
            # Return the created media post
            serializer = MediaPostSerializer(media_post)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to upload media: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['GET'])
    def liked_posts(self, request):
        """
        Get posts liked by the current user with proper pagination.
        """
        user = request.user
        
        # Get posts that the current user has liked, with proper visibility filtering
        liked_posts = Post.objects.filter(
            likes__user=user
        ).filter(
            Q(visibility='public') |
            Q(author=user) |
            (Q(visibility='followers') & Q(author__followers=user))
        ).annotate(
            comments_count=Count('comments', distinct=True),
            likes_count=Count('likes', distinct=True)
        ).order_by('-likes__created_at').distinct()
        
        # Apply pagination
        page = self.paginate_queryset(liked_posts)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(liked_posts, many=True)
        return Response(serializer.data)

class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_destroy(self, instance):
        """
        Override to ensure proper cascading delete for comments
        """
        # Check if user has permission to delete the comment
        if instance.author != self.request.user:
            raise permissions.PermissionDenied("You can only delete your own comments.")
        
        # The cascade delete is handled by the database due to on_delete=models.CASCADE
        # All related Like objects and child comments (replies) will be deleted automatically
        instance.delete()
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
    
    def get_queryset(self):
        queryset = Comment.objects.annotate(likes_count=Count('likes'))
        
        # Filter by post if post_id is provided in query params
        post_id = self.request.query_params.get('post')
        parent = self.request.query_params.get('parent')
        
        if post_id:
            try:
                post_id_int = int(post_id)
                queryset = queryset.filter(post_id=post_id_int)
            except (ValueError, TypeError):
                queryset = queryset.filter(post_id=post_id)
        
        if parent:
            if parent == 'null':
                queryset = queryset.filter(parent__isnull=True)
            else:
                try:
                    parent_id = int(parent)
                    queryset = queryset.filter(parent_id=parent_id)
                except (ValueError, TypeError):
                    queryset = queryset.filter(parent_id=parent)
                
        return queryset
    
    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        """Toggle like status on a comment."""
        try:
            comment = self.get_object()
            user = request.user
            
            # Check if the user already liked this comment
            like_exists = Like.objects.filter(
                user=user, comment=comment
            ).exists()
            
            if like_exists:
                # User already liked, so unlike
                Like.objects.filter(user=user, comment=comment).delete()
                return Response({'status': 'unliked'})
            else:
                # User hasn't liked, so add like
                Like.objects.create(user=user, comment=comment)
                return Response({'status': 'liked'})
                
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_400_BAD_REQUEST
            )

class TagViewSet(viewsets.ModelViewSet):
    """
    ViewSet for handling Tag model operations.
    """
    queryset = Tag.objects.all()
    serializer_class = TagSerializer
    authentication_classes = [JWTAuthentication]
    pagination_class = None  # Disable pagination for tags
    
    def get_permissions(self):
        """
        Instantiates and returns the list of permissions that this view requires.
        Allow reading tags without authentication, but require authentication for write operations.
        """
        if self.action in ['list', 'retrieve']:
            permission_classes = [permissions.AllowAny]
        else:
            permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = Tag.objects.all()
        
        # Filter by category if specified
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
            
        # Search by name
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | 
                Q(display_name_ar__icontains=search)
            )
            
        return queryset