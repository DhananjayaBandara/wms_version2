from rest_framework import serializers
from .models import UserAuth
from users.models import Participant
from django.contrib.auth.hashers import make_password

class UserAuthSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAuth
        fields = ['id', 'participant', 'nic', 'password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        password = validated_data.pop('password')
        user_auth = UserAuth(**validated_data)
        user_auth.set_password(password)
        return user_auth
    