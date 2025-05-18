from django.db.models.signals import post_save
from django.dispatch import receiver
from social.models import Like, Comment
from .social_notification_utils import send_social_notification

@receiver(post_save, sender=Like)
def notify_on_post_like(sender, instance, created, **kwargs):
    """
    Send notification when a post is liked
    """
    if created and instance.post:  # Only for new likes and on posts (not comments)
        # Don't notify if the author is liking their own post
        if instance.user.id == instance.post.author.id:
            return
              # Send notification to the post author
        send_social_notification(
            recipient_id=instance.post.author.id,
            sender=instance.user,
            notification_type='like',
            post_content=instance.post.content,
            sender_id=instance.user.id,
            post_id=instance.post.id
        )

@receiver(post_save, sender=Comment)
def notify_on_post_comment(sender, instance, created, **kwargs):
    """
    Send notification when a post is commented on
    """
    if created and not instance.parent:  # Only for new top-level comments (not replies)
        # Don't notify if the author is commenting on their own post
        if instance.author.id == instance.post.author.id:
            return
              # Send notification to the post author
        send_social_notification(
            recipient_id=instance.post.author.id,
            sender=instance.author,
            notification_type='comment',
            post_content=instance.post.content,
            sender_id=instance.author.id,
            post_id=instance.post.id
        )

# Handle comment replies separately
@receiver(post_save, sender=Comment)
def notify_on_comment_reply(sender, instance, created, **kwargs):
    """
    Send notification when a comment receives a reply
    """
    if created and instance.parent:  # Only for replies to comments
        # Don't notify if the person is replying to their own comment
        if instance.author.id == instance.parent.author.id:
            return
              # Send notification to the parent comment author
        send_social_notification(
            recipient_id=instance.parent.author.id,
            sender=instance.author,
            notification_type='comment',
            post_content=instance.content,  # Use the reply content instead of post content
            sender_id=instance.author.id,
            post_id=instance.post.id
        )
