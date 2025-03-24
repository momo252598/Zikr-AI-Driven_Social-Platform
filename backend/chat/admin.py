from django.contrib import admin
from .models import Conversation, Message, UserChatSettings

class MessageInline(admin.TabularInline):
    model = Message
    extra = 0

@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'firebase_id', 'name', 'created_at', 'updated_at')
    search_fields = ('name', 'firebase_id')
    filter_horizontal = ('participants',)
    inlines = [MessageInline]

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'sender', 'conversation', 'timestamp', 'is_read')
    list_filter = ('is_read', 'timestamp')
    search_fields = ('content_preview', 'sender__username')

@admin.register(UserChatSettings)
class UserChatSettingsAdmin(admin.ModelAdmin):
    list_display = ('user', 'notification_enabled', 'last_seen')
    filter_horizontal = ('muted_conversations',)
