from rest_framework import serializers
from .models import Post, Comment, Like, MediaPost, Tag, SavedPost
from accounts.serializers import UserSerializer

class MediaPostSerializer(serializers.ModelSerializer):
    class Meta:
        model = MediaPost
        fields = ['id', 'file_url', 'file_type', 'thumbnail_url']

class CommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    likes_count = serializers.IntegerField(read_only=True)
    is_liked = serializers.SerializerMethodField()
    id = serializers.IntegerField(read_only=True)  # Explicitly convert ID to integer
    
    class Meta:
        model = Comment
        fields = ['id', 'post', 'author', 'author_details', 'content', 'parent', 
                 'created_at', 'updated_at', 'is_edited', 'likes_count', 'is_liked']
        extra_kwargs = {
            'author': {'read_only': True},
            'post': {'required': True},  # Make sure post is required
        }
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ['id', 'name', 'display_name_ar', 'category', 'description']

class PostSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    media = MediaPostSerializer(many=True, read_only=True)
    comments_count = serializers.IntegerField(read_only=True)
    likes_count = serializers.IntegerField(read_only=True)
    is_liked = serializers.SerializerMethodField()
    id = serializers.IntegerField(read_only=True)
    tags = TagSerializer(many=True, read_only=True)
    tag_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = Post
        fields = ['id', 'author', 'author_details', 'content', 'created_at', 'updated_at', 
                 'visibility', 'media', 'comments_count', 'likes_count', 'is_liked', 'tags', 'tag_ids']
        extra_kwargs = {
            'author': {'read_only': True},
        }
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False
        
    def create(self, validated_data):
        tag_ids = validated_data.pop('tag_ids', [])
        post = Post.objects.create(**validated_data)
        
        # Add tags to post
        if tag_ids:
            tags = Tag.objects.filter(id__in=tag_ids)
            post.tags.set(tags)
            
        return post
        
    def update(self, instance, validated_data):
        tag_ids = validated_data.pop('tag_ids', None)
        
        # Update other fields
        instance = super().update(instance, validated_data)
        
        # Update tags if provided
        if tag_ids is not None:
            tags = Tag.objects.filter(id__in=tag_ids)
            instance.tags.set(tags)
            
        return instance