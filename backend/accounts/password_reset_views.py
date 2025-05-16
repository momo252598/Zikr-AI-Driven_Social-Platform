from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import get_user_model
import random
import string
from .models import AccountActivationToken

User = get_user_model()

@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    """
    API endpoint to handle the password reset request.
    Sends a 6-digit code to the user's email.
    """
    email = request.data.get('email', '').strip()
    
    if not email:
        return Response(
            {"error": "البريد الإلكتروني مطلوب."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Check if user exists
        user = User.objects.get(email=email)
        
        # Delete any existing reset tokens for this user
        AccountActivationToken.objects.filter(user=user).delete()
        
        # Generate a new 6-digit code
        code = ''.join(random.choices(string.digits, k=6))
        
        # Save the reset token
        AccountActivationToken.objects.create(user=user, token=code)
        
        # Send email with reset code
        send_reset_email(user, code)
        
        return Response(
            {"success": "تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني."},
            status=status.HTTP_200_OK
        )
    except User.DoesNotExist:
        return Response(
            {"error": "لم يتم العثور على حساب مرتبط بهذا البريد الإلكتروني."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {"error": f"حدث خطأ أثناء معالجة طلبك: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_reset_code(request):
    """
    API endpoint to verify the password reset code.
    """
    email = request.data.get('email', '').strip()
    token = request.data.get('token', '').strip()
    
    if not email or not token:
        return Response(
            {"error": "البريد الإلكتروني والرمز مطلوبان."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(email=email)
        token_obj = AccountActivationToken.objects.get(user=user, token=token)
        
        # Check if token is expired (24 hours)
        if timezone.now() > token_obj.created_at + timezone.timedelta(hours=24):
            return Response(
                {"error": "انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response(
            {"success": "تم التحقق من الرمز بنجاح."},
            status=status.HTTP_200_OK
        )
    except User.DoesNotExist:
        return Response(
            {"error": "لم يتم العثور على حساب مرتبط بهذا البريد الإلكتروني."},
            status=status.HTTP_404_NOT_FOUND
        )
    except AccountActivationToken.DoesNotExist:
        return Response(
            {"error": "رمز التحقق غير صحيح."},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response(
            {"error": f"حدث خطأ أثناء التحقق من الرمز: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    """
    API endpoint to reset the password after verification.
    """
    email = request.data.get('email', '').strip()
    token = request.data.get('token', '').strip()
    new_password = request.data.get('new_password', '')
    confirm_password = request.data.get('confirm_password', '')
    
    if not email or not token:
        return Response(
            {"error": "البريد الإلكتروني والرمز مطلوبان."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if not new_password or not confirm_password:
        return Response(
            {"error": "كلمة المرور الجديدة وتأكيدها مطلوبان."},
            status=status.HTTP_400_BAD_REQUEST
        )
        
    if new_password != confirm_password:
        return Response(
            {"error": "كلمة المرور وتأكيدها غير متطابقان."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(email=email)
        token_obj = AccountActivationToken.objects.get(user=user, token=token)
        
        # Check if token is expired (24 hours)
        if timezone.now() > token_obj.created_at + timezone.timedelta(hours=24):
            return Response(
                {"error": "انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Set the new password
        user.set_password(new_password)
        user.save()
        
        # Delete the token after use
        token_obj.delete()
        
        return Response(
            {"success": "تم تغيير كلمة المرور بنجاح."},
            status=status.HTTP_200_OK
        )
        
    except User.DoesNotExist:
        return Response(
            {"error": "لم يتم العثور على حساب مرتبط بهذا البريد الإلكتروني."},
            status=status.HTTP_404_NOT_FOUND
        )
    except AccountActivationToken.DoesNotExist:
        return Response(
            {"error": "رمز التحقق غير صحيح."},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response(
            {"error": f"حدث خطأ أثناء إعادة تعيين كلمة المرور: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

def send_reset_email(user, code):
    """
    Utility function to send password reset email.
    """
    subject = 'إعادة تعيين كلمة المرور'
    
    # Plain text version as fallback
    text_message = f"""
مرحبًا {user.username}،

رمز إعادة تعيين كلمة المرور الخاص بك هو: {code}

ستنتهي صلاحية هذا الرمز بعد 24 ساعة.

شكرًا،
فريق ذكر
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
            <div class="logo">ذكر</div>
        </div>
        <div class="content">
            <h2>مرحبًا {user.username}،</h2>
            <p>لقد تلقينا طلبًا لإعادة تعيين كلمة المرور الخاصة بحسابك. الرجاء استخدام الرمز التالي:</p>
            
            <div class="verification-code">{code}</div>
            
            <p>ستنتهي صلاحية هذا الرمز بعد 24 ساعة.</p>
            
            <p>إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذا البريد الإلكتروني.</p>
            
            <p>مع أطيب التحيات،<br>فريق ذكر</p>
        </div>
        <div class="footer">
            <p>&copy; {timezone.now().year} ذكر. جميع الحقوق محفوظة.</p>
        </div>
    </div>
</body>
</html>
"""
    
    email_from = settings.DEFAULT_FROM_EMAIL
    recipient_list = [user.email]
    
    send_mail(subject, text_message, email_from, recipient_list, 
             fail_silently=False, html_message=html_message)
