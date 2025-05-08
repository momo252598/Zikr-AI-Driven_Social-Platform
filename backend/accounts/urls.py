from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from accounts.views import verify_account, resend_verification_code, logout_view, update_profile, change_password, get_user_public_profile, check_auth
from .views import RegisterView, LoginView

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
]