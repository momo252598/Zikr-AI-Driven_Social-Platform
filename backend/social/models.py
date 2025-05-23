from django.db import models
from django.utils.translation import gettext as _
from accounts.models import User

class Post(models.Model):
    """Base Post model for all types of social content"""
    VISIBILITY_CHOICES = (
        ('public', 'Public'),
        ('followers', 'Followers Only'),
        ('private', 'Private'),
    )
    
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    visibility = models.CharField(max_length=10, choices=VISIBILITY_CHOICES, default='public')
    is_archived = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.author.username}'s post: {self.content[:50]}"

class MediaPost(models.Model):
    """Model for storing media attachments for posts"""
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='media')
    file_url = models.URLField()
    file_type = models.CharField(max_length=20)  # image, video, audio, document
    thumbnail_url = models.URLField(blank=True, null=True)
    
    def __str__(self):
        return f"Media for {self.post.id} - {self.file_type}"

class Comment(models.Model):
    """Model for post comments with hierarchical structure"""
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    parent = models.ForeignKey('self', null=True, blank=True, on_delete=models.CASCADE, related_name='replies')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_edited = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.author.username}'s comment: {self.content[:30]}"
    
    @property
    def replies_count(self):
        return Comment.objects.filter(parent=self).count()

class Like(models.Model):
    """Model for likes on posts and comments"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='likes')
    post = models.ForeignKey(Post, null=True, blank=True, on_delete=models.CASCADE, related_name='likes')
    comment = models.ForeignKey(Comment, null=True, blank=True, on_delete=models.CASCADE, related_name='likes')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        constraints = [
            models.CheckConstraint(
                check=(
                    models.Q(post__isnull=False, comment__isnull=True) | 
                    models.Q(post__isnull=True, comment__isnull=False)
                ),
                name='like_either_post_or_comment'
            ),
            models.UniqueConstraint(
                fields=['user', 'post'],
                condition=models.Q(post__isnull=False),
                name='unique_post_like_per_user'
            ),
            models.UniqueConstraint(
                fields=['user', 'comment'],
                condition=models.Q(comment__isnull=False),
                name='unique_comment_like_per_user'
            ),
        ]
    
    def __str__(self):
        target = self.post if self.post else self.comment
        return f"Like by {self.user.username} on {target}"

class Tag(models.Model):
    """Model for post tagging system"""
    CATEGORY_CHOICES = (
        ('religious', 'Religious Knowledge'),
        ('practice', 'Daily Practice'),
        ('lifestyle', 'Community & Lifestyle'),
        ('contemporary', 'Contemporary Issues'),
        ('community', 'Community Engagement'),
        ('suggestions', 'suggested'),
        ('other', 'Other'),
    )
    
    name = models.CharField(max_length=50, unique=True)
    display_name_ar = models.CharField(max_length=100, blank=True, null=True, help_text="Arabic display name for the tag")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='other')
    description = models.TextField(blank=True, null=True, help_text="Brief description of this tag topic")
    posts = models.ManyToManyField(Post, related_name='tags')
    
    def __str__(self):
        return self.name
    
    @property
    def posts_count(self):
        return self.posts.count()

class SavedPost(models.Model):
    """Model for users to save/bookmark posts"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_posts')
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='saved_by')
    saved_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'post')
    
    def __str__(self):
        return f"{self.user.username} saved post {self.post.id}"
