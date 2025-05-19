from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.utils.translation import gettext as _

class User(AbstractUser):
    USER_TYPE_CHOICES = (
        ('regular', 'Regular User'),
        ('sheikh', 'Sheikh'),
        ('admin', 'Admin'),
    )
    
    GENDER_CHOICES = (
        ('ذكر', 'Male'),
        ('أنثى', 'Female'),
    )
    
    email = models.EmailField(_('email address'), unique=True)
    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES, default='regular')
    phone_number = models.CharField(max_length=15, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    profile_picture = models.URLField(blank=True)
    bio = models.TextField(blank=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True, null=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True, 
                               help_text='Firebase Cloud Messaging token for push notifications')
    
    # Social fields
    followers = models.ManyToManyField('self', symmetrical=False, related_name='following', blank=True)
    
    # Add related_name attributes to avoid clashes
    groups = models.ManyToManyField(
        Group,
        related_name='user_set',  # Change this to avoid clash
        blank=True,
        help_text='The groups this user belongs to.',
        verbose_name='groups',
    )
    user_permissions = models.ManyToManyField(
        Permission,
        related_name='user_set',  # Change this to avoid clash
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions',
    )
    
    USERNAME_FIELD = 'email' # Change the default username field to email
    REQUIRED_FIELDS = ['username']
    
    def __str__(self):
        return self.username

class SheikhProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    certification = models.TextField()
    mosque = models.CharField(max_length=255)
    specialization = models.CharField(max_length=100)
    teaching_schedule = models.JSONField()  # Stores availability hours
    rating = models.FloatField(default=0.0)
    
    def __str__(self):
        return f"Sheikh Profile for {self.user.username}"
        
class SheikhVerification(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    certification_urls = models.JSONField()  # Stores list of certification image URLs from Supabase
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewer_notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"Sheikh Verification for {self.user.username} - {self.status}"

class AccountActivationToken(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    token = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Activation token for {self.user.username}"