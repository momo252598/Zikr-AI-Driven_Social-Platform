from django.shortcuts import render
from django.http import JsonResponse
from django.contrib.auth import login, authenticate
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from rest_framework import generics, status, permissions
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import PublicUserProfileSerializer, RegisterSerializer, CustomTokenObtainPairSerializer, UserSerializer, VerifyAccountSerializer, ChangePasswordSerializer
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
import random
import string
from .models import AccountActivationToken

User = get_user_model()

@csrf_exempt
def signup(request):
    if request.method == "POST":
        form = UserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return JsonResponse({"message": "User created successfully"}, status=201)
        else:
            return JsonResponse({"errors": form.errors}, status=400)
    return JsonResponse({"error": "Invalid request method"}, status=405)

@csrf_exempt
def login_view(request):
    if request.method == "POST":
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            return JsonResponse({"message": "Login successful"}, status=200)
        else:
            return JsonResponse({"errors": form.errors}, status=400)
    return JsonResponse({"error": "Invalid request method"}, status=405)

@api_view(['POST'])
@permission_classes([AllowAny])
def api_login(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    user = authenticate(username=username, password=password)
    
    if user is not None:
        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'username': user.username,
            'user_id': user.id
        })
    else:
        return Response({'error': 'Invalid credentials'}, status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def api_signup(request):
    username = request.data.get('username')
    password = request.data.get('password')
    email = request.data.get('email', '')
    
    # Additional fields for CustomUser
    user_type = request.data.get('user_type', 'regular')
    phone_number = request.data.get('phone_number', '')
    
    # Validation
    if not username or not password:
        return Response({'error': 'Username and password are required'}, status=400)
    
    if User.objects.filter(username=username).exists():
        return Response({'error': 'Username already taken'}, status=400)
    
    # Create the user
    try:
        # First create user with standard fields
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password
        )
        
        # Then set custom fields
        user.user_type = user_type
        user.phone_number = phone_number
        user.save()
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'message': 'User created successfully',
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'username': user.username,
            'user_id': user.id,
            'user_type': user.user_type
        }, status=201)
        
    except Exception as e:
        return Response({'error': str(e)}, status=400)

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Set is_verified to False
        user.is_verified = False
        user.save()
        
        # Generate a 6-digit verification code
        code = ''.join(random.choices(string.digits, k=6))
        
        # Save the verification code
        activation_token = AccountActivationToken.objects.create(user=user, token=code)
        
        # Send activation email with code
        self.send_activation_email(user, code)
        
        # Return data with token
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(user)
        
        data = UserSerializer(user).data
        data['tokens'] = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }
        data['message'] = "Account created successfully. Please check your email for the verification code."
        
        headers = self.get_success_headers(serializer.data)
        return Response(data, status=status.HTTP_201_CREATED, headers=headers)
    
    def send_activation_email(self, user, code):
        subject = 'Verify Your Account'
        
        # Plain text version as fallback
        text_message = f"""
Hi {user.username},

Your account verification code is: {code}

This code will expire in 24 hours.

Thanks,
Your App Team
"""
        
        # HTML version with CSS styling
        html_message = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{
            font-family: 'Helvetica Neue', Arial, sans-serif;
            color: #333333;
            line-height: 1.6;
            margin: 0;
            padding: 0;
        }}
        .container {{
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #ffffff;
        }}
        .header {{
            background-color: #6a3de2;
            padding: 20px;
            text-align: center;
            color: white;
            border-radius: 5px 5px 0 0;
        }}
        .content {{
            padding: 20px;
            border: 1px solid #e0e0e0;
            border-top: none;
            border-radius: 0 0 5px 5px;
        }}
        .verification-code {{
            font-size: 24px;
            font-weight: bold;
            color: #6a3de2;
            text-align: center;
            padding: 15px;
            margin: 20px 0;
            border: 2px dashed #6a3de2;
            border-radius: 5px;
            background-color: #f5f3ff;
        }}
        .footer {{
            text-align: center;
            margin-top: 20px;
            color: #777777;
            font-size: 12px;
        }}
        .logo {{
            font-size: 22px;
            font-weight: bold;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">Your App</div>
        </div>
        <div class="content">
            <h2>Hi {user.username},</h2>
            <p>Thank you for registering! Please use the following code to verify your account:</p>
            
            <div class="verification-code">{code}</div>
            
            <p>This code will expire in 24 hours.</p>
            
            <p>If you didn't create an account, you can safely ignore this email.</p>
            
            <p>Best regards,<br>Your App Team</p>
        </div>
        <div class="footer">
            <p>&copy; {timezone.now().year} Your App. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
"""
        
        email_from = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]
        
        send_mail(subject, text_message, email_from, recipient_list, 
                 fail_silently=False, html_message=html_message)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_account(request):
    serializer = VerifyAccountSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        token = serializer.validated_data['token']
        
        try:
            user = User.objects.get(email=email)
            token_obj = AccountActivationToken.objects.get(user=user, token=token)
            
            # Check if token is expired (24 hours)
            from django.utils import timezone
            import datetime
            
            if timezone.now() > token_obj.created_at + datetime.timedelta(hours=24):
                return Response(
                    {"error": "Verification code has expired. Please request a new one."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Activate the account
            user.is_verified = True
            user.save()
            
            # Delete the token
            token_obj.delete()
            
            return Response(
                {"success": "Account has been verified successfully."},
                status=status.HTTP_200_OK
            )
        except User.DoesNotExist:
            return Response(
                {"error": "User with this email does not exist."},
                status=status.HTTP_404_NOT_FOUND
            )
        except AccountActivationToken.DoesNotExist:
            return Response(
                {"error": "Invalid verification code."},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(TokenObtainPairView):
    permission_classes = (AllowAny,)
    serializer_class = CustomTokenObtainPairSerializer
    
    def post(self, request, *args, **kwargs):
        # Get the response from the parent class
        response = super().post(request, *args, **kwargs)
        
        # If login was successful
        if response.status_code == 200:
            # Update last_login timestamp
            username_or_email = request.data.get(User.USERNAME_FIELD)
            
            try:
                # Find the user by email (since that's your USERNAME_FIELD)
                user = User.objects.get(email=username_or_email)
                user.last_login = timezone.now()
                user.save(update_fields=['last_login'])
            except User.DoesNotExist:
                pass
        
        return response

@api_view(['POST'])
@permission_classes([AllowAny])
def resend_verification_code(request):
    email = request.data.get('email')
    if not email:
        return Response(
            {"error": "Email is required."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(email=email)
        
        # Don't resend if already verified
        if user.is_verified:
            return Response(
                {"message": "This account is already verified."},
                status=status.HTTP_200_OK
            )
        
        # Delete old token if exists
        AccountActivationToken.objects.filter(user=user).delete()
        
        # Generate new 6-digit code
        code = ''.join(random.choices(string.digits, k=6))
        
        # Save the new code
        AccountActivationToken.objects.create(user=user, token=code)
        
        # Send the email
        subject = 'Verify Your Account'
        
        # Plain text version
        text_message = f"""
Hi {user.username},

Your account verification code is: {code}

This code will expire in 24 hours.

Thanks,
Your App Team
"""
        
        # HTML version with CSS styling
        html_message = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{
            font-family: 'Helvetica Neue', Arial, sans-serif;
            color: #333333;
            line-height: 1.6;
            margin: 0;
            padding: 0;
        }}
        .container {{
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #ffffff;
        }}
        .header {{
            background-color: #6a3de2;
            padding: 20px;
            text-align: center;
            color: white;
            border-radius: 5px 5px 0 0;
        }}
        .content {{
            padding: 20px;
            border: 1px solid #e0e0e0;
            border-top: none;
            border-radius: 0 0 5px 5px;
        }}
        .verification-code {{
            font-size: 24px;
            font-weight: bold;
            color: #6a3de2;
            text-align: center;
            padding: 15px;
            margin: 20px 0;
            border: 2px dashed #6a3de2;
            border-radius: 5px;
            background-color: #f5f3ff;
        }}
        .footer {{
            text-align: center;
            margin-top: 20px;
            color: #777777;
            font-size: 12px;
        }}
        .logo {{
            font-size: 22px;
            font-weight: bold;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">Your App</div>
        </div>
        <div class="content">
            <h2>Hi {user.username},</h2>
            <p>You requested a new verification code. Please use the following code to verify your account:</p>
            
            <div class="verification-code">{code}</div>
            
            <p>This code will expire in 24 hours.</p>
            
            <p>If you didn't request this code, you can safely ignore this email.</p>
            
            <p>Best regards,<br>Your App Team</p>
        </div>
        <div class="footer">
            <p>&copy; {timezone.now().year} Your App. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
"""
        
        email_from = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]
        
        send_mail(subject, text_message, email_from, recipient_list, 
                 fail_silently=False, html_message=html_message)
        
        return Response(
            {"success": "Verification code has been sent to your email."},
            status=status.HTTP_200_OK
        )
        
    except User.DoesNotExist:
        return Response(
            {"error": "User with this email does not exist."},
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    try:
        refresh_token = request.data.get('refresh')
        if (refresh_token):
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"success": "Successfully logged out."}, status=status.HTTP_200_OK)
        else:
            return Response({"error": "Refresh token is required."}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Update user profile information
    """
    user = request.user
    serializer = UserSerializer(user, data=request.data, partial=True)
    
    if serializer.is_valid():
        # Prevent email changes
        if 'email' in serializer.validated_data:
            return Response(
                {"error": "Email address cannot be changed."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Change user password
    """
    serializer = ChangePasswordSerializer(data=request.data)
    
    if serializer.is_valid():
        # Check if old password is correct
        user = request.user
        old_password = serializer.validated_data['old_password']
        
        if not user.check_password(old_password):
            return Response(
                {"old_password": ["Wrong password."]},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Set the new password
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        return Response(
            {"success": "Password changed successfully."},
            status=status.HTTP_200_OK
        )
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_public_profile(request, user_id):
    """
    Retrieve basic public profile information for a specific user by ID.
    """
    try:
        user = User.objects.get(id=user_id)
        serializer = PublicUserProfileSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response(
            {"error": "User not found"},
            status=status.HTTP_404_NOT_FOUND
        )