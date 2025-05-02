from rest_framework import serializers
from .models import QuranBookmark, QuranReadingProgress

class QuranBookmarkSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = QuranBookmark
        fields = ['id', 'username', 'surah', 'verse', 'page', 'timestamp', 'notes']
        read_only_fields = ['id', 'username', 'timestamp']
    
    def create(self, validated_data):
        """Create or update the bookmark - if it exists already, update it"""
        user = self.context['request'].user
        
        # Check if the user already has this verse bookmarked
        try:
            bookmark = QuranBookmark.objects.get(
                user=user,
                surah=validated_data['surah'],
                verse=validated_data['verse']
            )
            # Update existing bookmark
            bookmark.notes = validated_data.get('notes', bookmark.notes)
            bookmark.save()
            return bookmark
        except QuranBookmark.DoesNotExist:
            # Create new bookmark - remove user from validated_data to prevent duplicate
            if 'user' in validated_data:
                validated_data.pop('user')  # Remove user if it exists in validated_data
            return QuranBookmark.objects.create(user=user, **validated_data)

class QuranReadingProgressSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = QuranReadingProgress
        fields = ['id', 'username', 'last_page', 'last_viewed']
        read_only_fields = ['id', 'username', 'last_viewed']
    
    def create(self, validated_data):
        """Create or update the reading progress"""
        user = self.context['request'].user
        
        # Try to get existing reading progress, or create a new one
        progress, created = QuranReadingProgress.objects.update_or_create(
            user=user,
            defaults={'last_page': validated_data.get('last_page', 1)}
        )
        return progress