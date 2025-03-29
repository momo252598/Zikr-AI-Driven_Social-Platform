from rest_framework import serializers
from .models import Conversation, Message, UserChatSettings
from accounts.models import User

class UserMinimalSerializer(serializers.ModelSerializer):
    """Minimal user representation for chat purposes"""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile_picture']

class ConversationSerializer(serializers.ModelSerializer):
    participants = UserMinimalSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ['id', 'firebase_id', 'created_at', 'updated_at', 'name', 'participants', 'last_message']
    
    def get_last_message(self, obj):
        """Get the latest message in the conversation"""
        last_message = obj.messages.order_by('-timestamp').first()
        if last_message:
            return {
                'content_preview': last_message.content_preview,
                'timestamp': last_message.timestamp,
                'sender': last_message.sender.username
            }
        return None

class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = ['id', 'firebase_id', 'conversation', 'sender', 'sender_username', 
                 'content_preview', 'timestamp', 'is_read']
    
    def get_sender_username(self, obj):
        return obj.sender.username

class UserChatSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserChatSettings
        fields = ['notification_enabled', 'last_seen']
        
class ConversationCreateSerializer(serializers.Serializer):
    """Serializer for creating a new conversation"""
    recipient = serializers.CharField(help_text="Username or email of the recipient")
    message = serializers.CharField(help_text="Initial message content", required=False, allow_blank=True, default='')