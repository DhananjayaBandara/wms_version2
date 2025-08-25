from rest_framework import serializers
from .models import TrainerCredential
from trainers.models import Trainer
from django.contrib.auth.hashers import make_password
from users.serializers import validate_email_format, validate_contact_number

class TrainerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Trainer
        fields = '__all__'
    
    def validate_email(self, value):
        return validate_email_format(value)

    def validate_contact_number(self, value):
        return validate_contact_number(value)
    

class TrainerCredentialSerializer(serializers.ModelSerializer):
    trainer_id = serializers.PrimaryKeyRelatedField(
        queryset=Trainer.objects.all(),
        source='trainer',
        write_only=True
    )
    trainer = TrainerSerializer(read_only=True)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = TrainerCredential
        fields = ['id', 'trainer', 'trainer_id', 'username', 'password']

    def create(self, validated_data):
        password = validated_data.pop('password')
        validated_data['password'] = make_password(password)
        return TrainerCredential.objects.create(**validated_data)

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.password = make_password(password)
        instance.save()
        return instance

