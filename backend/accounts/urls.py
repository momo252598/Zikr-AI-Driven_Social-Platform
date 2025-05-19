from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from accounts.views import verify_account, resend_verification_code, logout_view, update_profile, change_password, get_user_public_profile, check_auth, search_users, register_fcm_token
from .views import RegisterView, LoginView
from .password_reset_views import request_password_reset, verify_reset_code, reset_password
from .sheikh_views import upload_certification, submit_sheikh_certifications
from .admin_views import list_pending_sheikh_verifications, approve_sheikh_verification, reject_sheikh_verification

urlpatterns = [
    path('signup/', RegisterView.as_view(), name='auth_register'),
    path('login/', LoginView.as_view(), name='auth_login'),
    path('logout/', logout_view, name='auth_logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/verify-account/', verify_account, name='verify-account'),
    path('api/resend-verification/', resend_verification_code, name='resend-verification'),
    path("change-password/", change_password, name="change-password"),
    path('update-profile/', update_profile, name='update-profile'),
    path('user-profile/<int:user_id>/', get_user_public_profile, name='user-public-profile'),
    path('check-auth/', check_auth, name='check-auth'),
    path('search/', search_users, name='search-users'),
    path('register-fcm-token/', register_fcm_token, name='register-fcm-token'),
      # Password reset endpoints
    path('request-password-reset/', request_password_reset, name='request-password-reset'),
    path('verify-reset-code/', verify_reset_code, name='verify-reset-code'),
    path('reset-password/', reset_password, name='reset-password'),      # Sheikh verification endpoints
    path('submit-sheikh-certifications/', submit_sheikh_certifications, name='submit-sheikh-certifications'),
    path('upload-certification/', upload_certification, name='upload-certification'),
    
    # Admin sheikh verification endpoints
    path('admin/sheikh-verifications/', list_pending_sheikh_verifications, name='list-pending-sheikh-verifications'),
    path('admin/sheikh-verifications/<int:verification_id>/approve/', approve_sheikh_verification, name='approve-sheikh-verification'),
    path('admin/sheikh-verifications/<int:verification_id>/reject/', reject_sheikh_verification, name='reject-sheikh-verification'),
]