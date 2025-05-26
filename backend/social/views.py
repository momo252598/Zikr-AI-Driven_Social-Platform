import os
import uuid
from django.conf import settings
from supabase import create_client, Client
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.db.models import Count, Q

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
    permission_classes = [permissions.IsAuthenticated]
    
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