from django.apps import AppConfig

class ChatConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'chat'
    
    def ready(self):
        import chat.signals
        # Import here to avoid circular imports
        from .firebase_utils import initialize_firebase
        initialize_firebase()
