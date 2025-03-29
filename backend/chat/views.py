from django.shortcuts import render, get_object_or_404
from django.http import HttpResponse, JsonResponse
from django.db.models import Q
from django.utils import timezone
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Conversation, Message, UserChatSettings
from accounts.models import User
from .serializers import (
    ConversationSerializer, 
    MessageSerializer, 
    UserChatSettingsSerializer,
    ConversationCreateSerializer
)
import uuid
from .firebase_utils import create_firebase_custom_token

# Optional test view
def test_view(request):
    """
    A simple test view to verify that the chat URLs are working.
    """
    return HttpResponse("Chat app is working correctly!")

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_conversations(request):
    """
    Get all conversations for the current user.
    """
    user = request.user
    conversations = user.conversations.all()
    serializer = ConversationSerializer(conversations, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def start_conversation(request):
    """
    Start a new conversation with a user by username or email.
    """
    serializer = ConversationCreateSerializer(data=request.data)
    if serializer.is_valid():
        recipient_identifier = serializer.validated_data['recipient']
        initial_message = serializer.validated_data.get('message', '')
        
        # Find the recipient user
        try:
            # Check if the identifier is an email
            if '@' in recipient_identifier:
                recipient = User.objects.get(email=recipient_identifier)
            else:
                recipient = User.objects.get(username=recipient_identifier)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Don't allow starting a conversation with yourself
        if recipient.id == request.user.id:
            return Response(
                {"error": "You cannot start a conversation with yourself."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Check if a conversation already exists between these users
        existing_conversation = Conversation.objects.filter(
            participants=request.user
        ).filter(
            participants=recipient
        ).first()
        
        if existing_conversation:
            # If a conversation exists, return it
            conversation = existing_conversation
        else:
            # Create a new conversation
            firebase_id = str(uuid.uuid4())  # Generate a Firebase reference ID
            conversation = Conversation.objects.create(firebase_id=firebase_id)
            conversation.participants.add(request.user, recipient)
        
        # Only create a message reference if an initial message was provided
        message_firebase_id = None
        if initial_message:
            message_firebase_id = str(uuid.uuid4())
            message = Message.objects.create(
                conversation=conversation,
                sender=request.user,
                firebase_id=message_firebase_id,
                content_preview=initial_message[:97] + '...' if len(initial_message) > 100 else initial_message
            )
        
        # Update the conversation's timestamp
        conversation.updated_at = timezone.now()
        conversation.save()
        
        # Return the conversation details
        serializer = ConversationSerializer(conversation)
        response_data = {
            "conversation": serializer.data,
            "success": "Conversation started successfully."
        }
        
        # Only include message info if a message was created
        if message_firebase_id:
            response_data["message_firebase_id"] = message_firebase_id
            response_data["message_sent_to_firebase"] = False
        
        return Response(response_data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_conversation_detail(request, conversation_id):
    """
    Get details for a specific conversation.
    """
    conversation = get_object_or_404(Conversation, id=conversation_id)
    
    # Check if user is a participant
    if request.user not in conversation.participants.all():
        return Response(
            {"error": "You are not a participant in this conversation."},
            status=status.HTTP_403_FORBIDDEN
        )
    
    serializer = ConversationSerializer(conversation)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_message(request, conversation_id):
    """
    Add a message reference to a conversation.
    """
    conversation = get_object_or_404(Conversation, id=conversation_id)
    
    # Check if user is a participant
    if request.user not in conversation.participants.all():
        return Response(
            {"error": "You are not a participant in this conversation."},
            status=status.HTTP_403_FORBIDDEN
        )
    
    content = request.data.get('content', '')
    firebase_id = request.data.get('firebase_id', str(uuid.uuid4()))
    
    message = Message.objects.create(
        conversation=conversation,
        sender=request.user,
        firebase_id=firebase_id,
        content_preview=content[:97] + '...' if len(content) > 100 else content
    )
    
    # Update conversation timestamp
    conversation.updated_at = timezone.now()
    conversation.save()
    
    serializer = MessageSerializer(message)
    return Response(serializer.data, status=status.HTTP_201_CREATED)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def mark_messages_read(request, conversation_id):
    """
    Mark all messages in a conversation as read.
    """
    conversation = get_object_or_404(Conversation, id=conversation_id)
    
    # Check if user is a participant
    if request.user not in conversation.participants.all():
        return Response(
            {"error": "You are not a participant in this conversation."},
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Mark all messages sent by other users as read
    unread_messages = Message.objects.filter(
        conversation=conversation,
        is_read=False
    ).exclude(sender=request.user)
    
    count = unread_messages.count()
    unread_messages.update(is_read=True)
    
    # Update user's last seen time
    chat_settings, created = UserChatSettings.objects.get_or_create(user=request.user)
    chat_settings.last_seen = timezone.now()
    chat_settings.save()
    
    return Response({"marked_read": count}, status=status.HTTP_200_OK)

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def chat_settings(request):
    """
    Get or update user chat settings.
    """
    chat_settings, created = UserChatSettings.objects.get_or_create(user=request.user)
    
    if request.method == 'GET':
        serializer = UserChatSettingsSerializer(chat_settings)
        return Response(serializer.data)
    
    elif request.method == 'PUT':
        serializer = UserChatSettingsSerializer(chat_settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mute_conversation(request, conversation_id):
    """
    Mute or unmute a conversation.
    """
    conversation = get_object_or_404(Conversation, id=conversation_id)
    
    # Check if user is a participant
    if request.user not in conversation.participants.all():
        return Response(
            {"error": "You are not a participant in this conversation."},
            status=status.HTTP_403_FORBIDDEN
        )
    
    chat_settings, created = UserChatSettings.objects.get_or_create(user=request.user)
    mute = request.data.get('mute', True)
    
    if mute:
        chat_settings.muted_conversations.add(conversation)
        message = "Conversation muted"
    else:
        chat_settings.muted_conversations.remove(conversation)
        message = "Conversation unmuted"
    
    return Response({"status": message}, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_firebase_token(request):
    """Endpoint to get a Firebase custom token for the authenticated user"""
    user_id = request.user.id
    firebase_token = create_firebase_custom_token(user_id)
    return JsonResponse({'firebase_token': firebase_token.decode()})
