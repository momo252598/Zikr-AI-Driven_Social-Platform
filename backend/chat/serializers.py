from rest_framework import serializers
from .models import Conversation, Message, UserChatSettings
from accounts.models import User

class UserMinimalSerializer(serializers.ModelSerializer):
    """Minimal user representation for chat purposes"""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile_picture', 'first_name', 'last_name']

class ConversationSerializer(serializers.ModelSerializer):
    participants = UserMinimalSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ['id', 'firebase_id', 'created_at', 'updated_at', 'name', 'participants', 'last_message', 'unread_count']
    
    def get_last_message(self, obj):
        """Get the latest message in the conversation"""
        last_message = obj.messages.order_by('-timestamp').first()
        if last_message:
            return {
                'content_preview': last_message.content_preview,
                'timestamp': last_message.timestamp,
                'sender': last_message.sender.username,
                'sender_id': last_message.sender.id,
                'is_read': last_message.is_read
            }
        return None
    def get_unread_count(self, obj):
        """Get the count of unread messages for the current user in this conversation"""
        request = self.context.get('request')
        if not request or not hasattr(request, 'user') or not request.user:
            return 0
        user = request.user
        # Count unread messages that were NOT sent by the current user
        return obj.messages.filter(is_read=False).exclude(sender=user).count()

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