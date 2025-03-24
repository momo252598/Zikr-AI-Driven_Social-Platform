from django.urls import path
from . import views

app_name = 'chat'

urlpatterns = [
    path('test/', views.test_view, name='test'),
    path('conversations/', views.get_conversations, name='conversations'),
    path('conversations/start/', views.start_conversation, name='start_conversation'),
    path('conversations/<int:conversation_id>/', views.get_conversation_detail, name='conversation_detail'),
    path('conversations/<int:conversation_id>/messages/add/', views.add_message, name='add_message'),
    path('conversations/<int:conversation_id>/read/', views.mark_messages_read, name='mark_read'),
    path('conversations/<int:conversation_id>/mute/', views.mute_conversation, name='mute_conversation'),
    path('settings/', views.chat_settings, name='chat_settings'),
    path('firebase-token/', views.get_firebase_token, name='firebase_token'),
]

