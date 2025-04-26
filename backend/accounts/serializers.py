from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework.validators import UniqueValidator
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    # Define gender as a ChoiceField with custom handling for quotes
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
    ]
    gender = serializers.ChoiceField(choices=GENDER_CHOICES, required=False)
    
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'user_type', 'phone_number', 
                 'birth_date', 'profile_picture', 'bio', 'is_verified', 
                 'created_at', 'first_name', 'last_name', 'date_joined', 'last_login',
                 'gender')
        read_only_fields = ('id', 'date_joined', 'last_login')
    
    def validate_gender(self, value):
        """
        Handle quoted gender values from frontend.
        """
        if value is None:
            return value
            
        # Handle potential quoted strings
        if isinstance(value, str):
            # Remove any quotes that might be in the string
            clean_value = value.replace('"', '').replace("'", '').strip().lower()
            
            # Check if the cleaned value is valid
            valid_choices = [choice[0] for choice in self.GENDER_CHOICES]
            if clean_value in valid_choices:
                return clean_value
                
        # If we get here with the original value, validate as normal
        return value


class RegisterSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(
        required=True,
        validators=[UniqueValidator(queryset=User.objects.all())]
    )
    password = serializers.CharField(
        write_only=True, 
        required=True, 
        validators=[validate_password]
    )
    password2 = serializers.CharField(write_only=True, required=True)
    birth_date = serializers.DateField(required=False)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    
    # Change gender to a ChoiceField with predefined options
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
    ]
    gender = serializers.ChoiceField(choices=GENDER_CHOICES, required=False)

    class Meta:
        model = User
        fields = ('username', 'password', 'password2', 'email', 'user_type', 
                 'phone_number', 'birth_date', 'first_name', 'last_name', 'gender')

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Add custom claims
        token['username'] = user.username
        token['email'] = user.email
        token['user_type'] = user.user_type
        return token
    
    def validate(self, attrs):
        # The default USERNAME_FIELD is 'email', but we want to allow login with username too
        
        # Get the username/email field from attrs
        credential = attrs.get(self.username_field)
        password = attrs.get('password')
        
        if credential and password:
            # Check if the credential is an email (contains @)
            if '@' in credential:
                # Try to authenticate with email
                try:
                    user = User.objects.get(email=credential)
                    if user.check_password(password):
                        self.user = user
                    else:
                        raise serializers.ValidationError(
                            {'password': 'No active account found with the given credentials.'}
                        )
                except User.DoesNotExist:
                    raise serializers.ValidationError(
                        {'email': 'No active account found with the given credentials.'}
                    )
            else:
                # Try to authenticate with username
                try:
                    user = User.objects.get(username=credential)
                    if user.check_password(password):
                        self.user = user
                    else:
                        raise serializers.ValidationError(
                            {'password': 'No active account found with the given credentials.'}
                        )
                except User.DoesNotExist:
                    raise serializers.ValidationError(
                        {'username': 'No active account found with the given credentials.'}
                    )
        else:
            raise serializers.ValidationError(
                {'credential': 'Both username/email and password are required.'}
            )
        
        data = {}
        
        # Get the token
        refresh = self.get_token(self.user)
        
        data['refresh'] = str(refresh)
        data['access'] = str(refresh.access_token)
        
        # Use UserSerializer to get all user fields
        user_serializer = UserSerializer(self.user)
        user_data = user_serializer.data
        
        # Add all user data to the response
        data.update({
            'user': user_data
        })
        
        return data

class VerifyAccountSerializer(serializers.Serializer):
    email = serializers.EmailField()
    token = serializers.CharField(help_text="The 6-digit verification code sent to the user's email")

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    confirm_password = serializers.CharField(required=True)
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Password fields didn't match."})
        return attrs

class PublicUserProfileSerializer(serializers.ModelSerializer):
    """Serializer for public-facing user profile data"""
    name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ('id', 'username', 'name', 'profile_picture', 'user_type', 'is_verified')
    
    def get_name(self, obj):
        # Combine first_name and last_name into a single field
        if obj.first_name or obj.last_name:
            return f"{obj.first_name} {obj.last_name}".strip()
        return obj.username