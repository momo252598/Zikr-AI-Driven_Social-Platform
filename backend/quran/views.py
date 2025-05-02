from django.shortcuts import render
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import QuranBookmark, QuranReadingProgress
from .serializers import QuranBookmarkSerializer, QuranReadingProgressSerializer

# Create your views here.

class BookmarkListCreateView(generics.ListCreateAPIView):
    """View for listing and creating Quran bookmarks"""
    serializer_class = QuranBookmarkSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return only the current user's bookmarks"""
        return QuranBookmark.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        """Save the current user as the bookmark owner"""
        serializer.save(user=self.request.user)

class BookmarkDeleteView(generics.DestroyAPIView):
    """View for deleting a specific bookmark"""
    serializer_class = QuranBookmarkSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Ensure users can only delete their own bookmarks"""
        return QuranBookmark.objects.filter(user=self.request.user)

class ReadingProgressView(APIView):
    """View for getting or updating the user's reading progress"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """Get the user's reading progress"""
        try:
            progress = QuranReadingProgress.objects.get(user=request.user)
            serializer = QuranReadingProgressSerializer(progress)
            return Response(serializer.data)
        except QuranReadingProgress.DoesNotExist:
            # Return default values if no progress exists yet
            return Response({
                'last_page': 1,
                'last_viewed': None
            })
    
    def post(self, request):
        """Update the user's reading progress"""
        try:
            progress = QuranReadingProgress.objects.get(user=request.user)
            serializer = QuranReadingProgressSerializer(
                progress, 
                data=request.data, 
                context={'request': request}  # Pass request context here
            )
        except QuranReadingProgress.DoesNotExist:
            # Create new reading progress if it doesn't exist
            serializer = QuranReadingProgressSerializer(
                data=request.data,
                context={'request': request}  # Pass request context here
            )
        
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
