import firebase_admin
from firebase_admin import credentials, auth, messaging
import os

def initialize_firebase():
    # Get your service account key from Firebase console > Project settings > Service accounts
    # Use path relative to this file instead of working directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    credentials_path = os.path.join(current_dir, "../zikr-94f9a-firebase-adminsdk-fbsvc-8c693eec91.json")
    
    # Alternative: use environment variable (more secure for production)
    # credentials_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", credentials_path)
    
    cred = credentials.Certificate(credentials_path)
    
    # Initialize the app if it hasn't been initialized already
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)

def create_firebase_custom_token(user_id):
    """Generate a custom Firebase token for a Django user"""
    initialize_firebase()
    try:
        # Convert user_id to string as Firebase requires
        uid = str(user_id)
        token = auth.create_custom_token(uid)
        return token.decode('utf-8')
    except Exception as e:
        print(f"Error creating firebase token: {e}")
        return None

def send_message_notification(recipient_id, sender_name, message_content, conversation_id):
    """
    Send a push notification to a user when they receive a new message
    
    Args:
        recipient_id (int): The ID of the user receiving the message
        sender_name (str): The name of the message sender
        message_content (str): The content of the message
        conversation_id (str): The Firebase ID of the conversation
    """
    initialize_firebase()
    
    try:
        # Import User model here to avoid circular import
        from accounts.models import User
        
        # Get recipient's FCM token
        try:
            recipient = User.objects.get(id=recipient_id)
            if not recipient.fcm_token:
                print(f"No FCM token available for user {recipient_id}")
                return
                
            token = recipient.fcm_token
            
            # Create message notification
            message = messaging.Message(
                data={
                    'type': 'chat_message',
                    'senderName': sender_name,
                    'messageContent': message_content,
                    'conversationId': conversation_id
                },
                notification=messaging.Notification(
                    title=sender_name,
                    body=message_content
                ),
                token=token,
            )
            
            # Send message
            response = messaging.send(message)
            print(f"Successfully sent notification to {recipient_id}: {response}")
            
        except User.DoesNotExist:
            print(f"User {recipient_id} not found")
            
    except Exception as e:
        print(f"Error sending push notification: {e}")

def send_notification_to_topic(topic, title, body, data=None):
    """
    Send a notification to a topic subscription
    
    Args:
        topic (str): The topic to send to (e.g. 'chat_123')
        title (str): The notification title
        body (str): The notification body
        data (dict, optional): Additional data to send
    """
    initialize_firebase()
    
    try:
        # Create a message for a topic
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data or {},
            topic=topic,
        )
        
        # Send message
        response = messaging.send(message)
        print(f"Successfully sent notification to topic {topic}: {response}")
        
    except Exception as e:
        print(f"Error sending topic notification: {e}")