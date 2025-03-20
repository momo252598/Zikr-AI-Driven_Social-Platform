from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework.validators import UniqueValidator
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'user_type', 'phone_number', 
                 'birth_date', 'profile_picture', 'bio', 'is_verified', 
                 'created_at', 'first_name', 'last_name', 'date_joined', 'last_login',
                 'gender')
        read_only_fields = ('id', 'date_joined', 'last_login')


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
        data = super().validate(attrs)
        
        # Use UserSerializer to get all user fields
        user_serializer = UserSerializer(self.user)
        user_data = user_serializer.data
        
        # Add all user data to the response
        data.update({
            'user': user_data
        })
        
        return data