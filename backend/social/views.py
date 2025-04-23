from django.shortcuts import render

# Create your views here.
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.db.models import Count, Q

from .models import Post, Comment, Like, MediaPost
from .serializers import PostSerializer, CommentSerializer

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
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_queryset(self):
        # Filter by visibility based on relationship with the author
        user = self.request.user
        return Post.objects.filter(
            Q(visibility='public') |
            Q(author=user) |
            (Q(visibility='followers') & Q(author__followers=user))
        ).annotate(
            comments_count=Count('comments', distinct=True),
            likes_count=Count('likes', distinct=True)
        ).order_by('-created_at')
    
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
    
    @action(detail=True, methods=['POST'])
    def add_media(self, request, pk=None):
        post = self.get_object()
        file_url = request.data.get('file_url')
        file_type = request.data.get('file_type', 'image')
        thumbnail_url = request.data.get('thumbnail_url', '')
        
        if not file_url:
            return Response(
                {'error': 'File URL is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        media = MediaPost.objects.create(
            post=post,
            file_url=file_url,
            file_type=file_type,
            thumbnail_url=thumbnail_url
        )
        
        return Response({'id': media.id, 'file_url': media.file_url}, status=status.HTTP_201_CREATED)

class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    
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