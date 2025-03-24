from django.db.models.signals import post_save
from django.dispatch import receiver
from accounts.models import User
from .models import UserChatSettings

@receiver(post_save, sender=User)
def create_user_chat_settings(sender, instance, created, **kwargs):
    """Create UserChatSettings when a new User is created"""
    if created:
        UserChatSettings.objects.create(user=instance)