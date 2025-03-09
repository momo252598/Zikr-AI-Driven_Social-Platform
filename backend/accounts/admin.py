from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _

from .models import User

class CustomUserAdmin(UserAdmin):
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'email', 'user_type', 'phone_number', 'bio', 'profile_picture', 'birth_date')}),
        (_('Permissions'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'is_verified', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {'fields': ('last_login', 'date_joined', 'created_at')}),
    )
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'user_type')
    search_fields = ('username', 'email', 'first_name', 'last_name')
    readonly_fields = ('created_at',)

admin.site.register(User, CustomUserAdmin)
