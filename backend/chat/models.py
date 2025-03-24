from django.db import models
from accounts.models import User
from django.utils import timezone

class Conversation(models.Model):
    """Represents a conversation between users"""
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    firebase_id = models.CharField(max_length=100, unique=True)
    
    # The users participating in this conversation
    participants = models.ManyToManyField(User, related_name='conversations')
    
    # For one-on-one chats, this can be empty. For group chats, this can store the name.
    name = models.CharField(max_length=255, blank=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        if self.name:
            return self.name
        return f"Conversation {self.id}"
    
    def get_other_participant(self, user):
        """Helper method to get the other participant in a one-on-one conversation"""
        return self.participants.exclude(id=user.id).first()


class Message(models.Model):
    """Reference to messages stored in Firebase"""
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    firebase_id = models.CharField(max_length=100)
    timestamp = models.DateTimeField(default=timezone.now)
    
    # You can store a preview or the first part of the message here
    # This helps with displaying message previews without fetching from Firebase
    content_preview = models.CharField(max_length=100, blank=True)
    
    # Track message status
    is_read = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['timestamp']
    
    def __str__(self):
        return f"Message from {self.sender.username} in {self.conversation}"


class UserChatSettings(models.Model):
    """User preferences for the chat system"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='chat_settings')
    muted_conversations = models.ManyToManyField(Conversation, blank=True, related_name='muted_by')
    notification_enabled = models.BooleanField(default=True)
    last_seen = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Chat settings for {self.user.username}"
