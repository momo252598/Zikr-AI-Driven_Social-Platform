from django.db import models
from django.conf import settings

class QuranBookmark(models.Model):
    """Model for storing user's Quran bookmarks"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='quran_bookmarks')
    surah = models.IntegerField(help_text="Surah number (1-114)")
    verse = models.IntegerField(help_text="Verse/Ayah number")
    page = models.IntegerField(help_text="Quran page number")
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True, help_text="Optional notes for this bookmark")
    
    class Meta:
        unique_together = ('user', 'surah', 'verse')  # Each user can bookmark a verse only once
        ordering = ['-timestamp']  # Most recent bookmarks first
    
    def __str__(self):
        return f"{self.user.username} - Surah {self.surah}, Verse {self.verse}"

class QuranReadingProgress(models.Model):
    """Model for tracking user's last read Quran page"""
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='quran_reading_progress')
    last_page = models.IntegerField(default=1, help_text="Last Quran page the user was reading")
    last_viewed = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username} - Last read page: {self.last_page}"
