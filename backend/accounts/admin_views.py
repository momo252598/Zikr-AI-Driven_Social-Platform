from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework import status
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone

from .models import User, SheikhVerification
from .serializers import UserSerializer

@api_view(['GET'])
@permission_classes([IsAdminUser])
def list_pending_sheikh_verifications(request):
    """
    List all pending sheikh verifications
    Only accessible by admin users
    """
    # Get all pending verifications
    pending_verifications = SheikhVerification.objects.filter(status='pending')
    
    # Prepare the response data
    pending_data = []
    for verification in pending_verifications:
        user_data = UserSerializer(verification.user).data
        verification_data = {
            'id': verification.id,
            'user_id': verification.user.id,
            'username': verification.user.username,
            'first_name': verification.user.first_name,
            'last_name': verification.user.last_name,
            'email': verification.user.email,
            'certification_urls': verification.certification_urls,
            'submitted_at': verification.submitted_at,
        }
        pending_data.append(verification_data)
    
    return Response(pending_data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAdminUser])
def approve_sheikh_verification(request, verification_id):
    """
    Approve a sheikh verification request
    Only accessible by admin users
    """
    try:
        verification = SheikhVerification.objects.get(id=verification_id)
    except SheikhVerification.DoesNotExist:
        return Response(
            {'error': 'Verification request not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    if verification.status != 'pending':
        return Response(
            {'error': 'This verification request has already been processed'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Update verification status
    verification.status = 'approved'
    verification.reviewed_at = timezone.now()
    verification.reviewer_notes = request.data.get('notes', '')
    verification.save()
    
    # Update user account type
    user = verification.user
    user.user_type = 'sheikh'
    user.save()
    
    # Send approval email
    subject = 'تم قبول طلب توثيق حساب الشيخ الخاص بك'
    text_message = f"""
مرحبًا {user.first_name} {user.last_name}،

يسرنا إعلامك أنه تم قبول طلب توثيق حساب الشيخ الخاص بك. الآن يمكنك استخدام جميع ميزات حساب الشيخ.

مع أطيب التحيات،
فريق ذكر
    """
    
    html_message = f"""
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تم قبول طلب التوثيق</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap');
        
        body, html {{
            font-family: 'Cairo', sans-serif;
            text-align: right;
            direction: rtl;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }}
        
        .container {{
            max-width: 600px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }}
        
        .header {{
            background: #6A4B9B;
            color: #ffffff;
            padding: 20px;
            text-align: center;
        }}
        
        .logo {{
            font-size: 28px;
            font-weight: bold;
        }}
        
        .content {{
            padding: 30px;
            color: #444;
        }}
        
        h2 {{
            color: #6A4B9B;
            margin-top: 0;
        }}
        
        .success-message {{
            padding: 15px;
            background-color: #e8f5e9;
            border-radius: 8px;
            border-right: 5px solid #4caf50;
            margin: 15px 0;
            font-weight: bold;
            color: #2e7d32;
        }}
        
        .footer {{
            background: #f9f9f9;
            padding: 15px;
            text-align: center;
            color: #777;
            font-size: 14px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ذكر</div>
        </div>
        <div class="content">
            <h2>مرحبًا {user.first_name} {user.last_name}،</h2>
            
            <div class="success-message">
                تهانينا! تم قبول طلب توثيق حساب الشيخ الخاص بك.
            </div>
            
            <p>يسرنا إعلامك أنه تم مراجعة الوثائق المقدمة والموافقة على طلب توثيق حسابك كشيخ.</p>
            
            <p>يمكنك الآن الاستفادة من جميع ميزات حساب الشيخ على منصتنا.</p>
            
            <p>إذا كانت لديك أي استفسارات، فلا تتردد في التواصل معنا.</p>
            
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
    
    return Response({
        'message': 'Sheikh verification approved successfully',
        'user_id': user.id,
        'username': user.username
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAdminUser])
def reject_sheikh_verification(request, verification_id):
    """
    Reject a sheikh verification request
    Only accessible by admin users
    """
    try:
        verification = SheikhVerification.objects.get(id=verification_id)
    except SheikhVerification.DoesNotExist:
        return Response(
            {'error': 'Verification request not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    if verification.status != 'pending':
        return Response(
            {'error': 'This verification request has already been processed'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Update verification status
    verification.status = 'rejected'
    verification.reviewed_at = timezone.now()
    verification.reviewer_notes = request.data.get('notes', '')
    verification.save()
    
    # Ensure user remains regular
    user = verification.user
    user.user_type = 'regular'
    user.save()
    
    # Send rejection email
    subject = 'تم رفض طلب توثيق حساب الشيخ الخاص بك'
    
    rejection_reason = request.data.get('notes', 'الوثائق المقدمة غير كافية')
    
    text_message = f"""
مرحبًا {user.first_name} {user.last_name}،

نأسف لإبلاغك أنه تم رفض طلب توثيق حساب الشيخ الخاص بك للأسباب التالية:

{rejection_reason}

يمكنك تقديم طلب جديد مع وثائق إضافية في وقت لاحق.

مع أطيب التحيات،
فريق ذكر
    """
    
    html_message = f"""
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تم رفض طلب التوثيق</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap');
        
        body, html {{
            font-family: 'Cairo', sans-serif;
            text-align: right;
            direction: rtl;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }}
        
        .container {{
            max-width: 600px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }}
        
        .header {{
            background: #6A4B9B;
            color: #ffffff;
            padding: 20px;
            text-align: center;
        }}
        
        .logo {{
            font-size: 28px;
            font-weight: bold;
        }}
        
        .content {{
            padding: 30px;
            color: #444;
        }}
        
        h2 {{
            color: #6A4B9B;
            margin-top: 0;
        }}
        
        .rejection-message {{
            padding: 15px;
            background-color: #ffebee;
            border-radius: 8px;
            border-right: 5px solid #f44336;
            margin: 15px 0;
            font-weight: bold;
            color: #c62828;
        }}
        
        .reason-box {{
            background-color: #f9f9f9;
            border: 1px solid #eee;
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
        }}
        
        .footer {{
            background: #f9f9f9;
            padding: 15px;
            text-align: center;
            color: #777;
            font-size: 14px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">ذكر</div>
        </div>
        <div class="content">
            <h2>مرحبًا {user.first_name} {user.last_name}،</h2>
            
            <div class="rejection-message">
                نأسف لإبلاغك أنه تم رفض طلب توثيق حساب الشيخ الخاص بك.
            </div>
            
            <p>بعد مراجعة المستندات المقدمة، لم نتمكن من الموافقة على طلبك للأسباب التالية:</p>
            
            <div class="reason-box">
                {rejection_reason}
            </div>
            
            <p>يمكنك تقديم طلب جديد مع الوثائق المطلوبة في وقت لاحق.</p>
            
            <p>نشكرك على تفهمك وصبرك.</p>
            
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
    
    return Response({
        'message': 'Sheikh verification rejected successfully',
        'user_id': user.id,
        'username': user.username
    }, status=status.HTTP_200_OK)
