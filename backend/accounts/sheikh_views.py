from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from django.conf import settings
import uuid
import os
import traceback
from supabase import create_client
from .models import User, SheikhVerification

@api_view(['GET'])
@permission_classes([AllowAny])
def check_verification_status(request, user_id):
    """
    Check if a user has any pending sheikh verification requests
    """
    try:
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check for pending verification requests
        has_pending = SheikhVerification.objects.filter(
            user=user, 
            status='pending'
        ).exists()
        
        return Response({
            'has_pending_request': has_pending,
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        # Print detailed error for debugging
        print(f"Error checking verification status: {str(e)}")
        print(traceback.format_exc())
        
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
@parser_classes([MultiPartParser, FormParser])
def upload_certification(request):
    """
    Upload sheikh certification image to Supabase
    """
    try:
        # Get the file from request
        file_obj = request.FILES.get('file')
        if not file_obj:
            return Response({'error': 'No file provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Create a unique filename with original extension
        original_name = file_obj.name
        extension = os.path.splitext(original_name)[1].lower()
        unique_filename = f"sheikh_certifications/{uuid.uuid4()}{extension}"
        
        # Get file content
        file_content = file_obj.read()
        
        # Initialize Supabase client
        supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        
        # Upload to Supabase
        supabase.storage.from_(settings.SUPABASE_SHEIKH_BUCKET).upload(
            unique_filename,
            file_content,
            file_options={"contentType": file_obj.content_type}
        )
        
        # Get the public URL
        file_url = supabase.storage.from_(settings.SUPABASE_SHEIKH_BUCKET).get_public_url(unique_filename)
        
        # Return the file URL
        return Response({
            'file_url': file_url,
            'message': 'Certification uploaded successfully'
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        # Print detailed error for debugging
        print(f"Error in upload_certification: {str(e)}")
        print(traceback.format_exc())
        
        return Response(
            {'error': f'Failed to upload certification: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def submit_sheikh_certifications(request):
    """
    Submit sheikh certification images for verification
    """
    try:
        email = request.data.get('email')
        certification_urls = request.data.get('certification_urls')
        
        if not email or not certification_urls:
            return Response({
                'error': 'Email and certification URLs are required'
            }, status=status.HTTP_400_BAD_REQUEST)
            
        # Find the user by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
            
        # Create or update sheikh verification
        verification, created = SheikhVerification.objects.update_or_create(
            user=user,
            defaults={
                'certification_urls': certification_urls,
                'status': 'pending'
            }
        )
        
        return Response({
            'message': 'Certification images submitted successfully',
            'status': 'pending'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        # Print detailed error for debugging
        print(f"Error in submit_sheikh_certifications: {str(e)}")
        print(traceback.format_exc())
        
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
