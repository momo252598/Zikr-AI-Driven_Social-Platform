from chat.firebase_utils import initialize_firebase
from firebase_admin import messaging
from accounts.models import User
import json

def send_social_notification(recipient_id, sender, notification_type, post_content, sender_id, post_id):
    """
    Send a push notification to a user for social interactions (likes, comments)
    
    Args:
        recipient_id (int): The ID of the post author receiving the notification
        sender (User): The user object who liked/commented
        notification_type (str): The type of notification ('like' or 'comment')
        post_content (str): The content of the post (truncated)
        sender_id (str): The ID of the user who triggered the notification
        post_id (str): The ID of the post
    """
    initialize_firebase()
    
    try:
        # Import User model here to avoid circular import
        # Get recipient's FCM token
        try:
            recipient = User.objects.get(id=recipient_id)
            if not recipient.fcm_token:
                print(f"No FCM token available for user {recipient_id}")
                return
                
            token = recipient.fcm_token
              # Get sender's full name, or use username as fallback
            sender_full_name = f"{sender.first_name} {sender.last_name}".strip()
            if not sender_full_name:
                sender_full_name = sender.username
            
            # Create different message based on notification type
            if notification_type == 'like':
                title = f"{sender_full_name} أعجب بمنشورك"
                body = post_content[:100] + '...' if len(post_content) > 100 else post_content
            elif notification_type == 'comment':
                title = f"{sender_full_name} علق على منشورك"
                body = post_content[:100] + '...' if len(post_content) > 100 else post_content
            else:
                # Unknown notification type
                return
            
            # Create notification message
            message = messaging.Message(
                data={
                    'type': 'social_notification',
                    'notificationType': notification_type,
                    'senderName': sender_full_name,
                    'postContent': post_content[:200],  # Limit content length
                    'senderId': str(sender_id),
                    'postId': str(post_id)
                },
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                token=token,
            )
            
            # Send message
            response = messaging.send(message)
            print(f"Successfully sent {notification_type} notification to {recipient_id}: {response}")
            
        except User.DoesNotExist:
            print(f"User {recipient_id} not found")
            
    except Exception as e:
        print(f"Error sending social notification: {e}")
