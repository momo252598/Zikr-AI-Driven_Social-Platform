import firebase_admin
from firebase_admin import credentials, auth
import os

def initialize_firebase():
    # Get your service account key from Firebase console > Project settings > Service accounts
    # Use path relative to this file instead of working directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    credentials_path = os.path.join(current_dir, "../zikr-94f9a-firebase-adminsdk-fbsvc-d32aba577e.json")
    
    # Alternative: use environment variable (more secure for production)
    # credentials_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", credentials_path)
    
    cred = credentials.Certificate("D:\College\Flutter_Projects\software_graduation_project\\backend\zikr-94f9a-firebase-adminsdk-fbsvc-8c693eec91.json")
    
    # Initialize the app if it hasn't been initialized already
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)

# filepath: d:\College\Flutter_Projects\software_graduation_project\backend\chat\firebase_utils.py
def create_firebase_custom_token(user_id):
    """Generate a custom Firebase token for a Django user"""
    if not firebase_admin._apps:
        initialize_firebase()
    
    user_id_str = str(user_id)
    print(f"Creating Firebase token for user ID: {user_id_str}")
    
    try:
        # Add explicit claims object
        claims = {
            "uid": user_id_str,  # Explicitly set UID
            "django_user_id": user_id  # Add additional info if needed
        }
        
        token = auth.create_custom_token(user_id_str, claims)
        print(f"Token created successfully: {token[:20]}...")
        return token
    except Exception as e:
        print(f"Error creating Firebase token: {e}")
        raise e