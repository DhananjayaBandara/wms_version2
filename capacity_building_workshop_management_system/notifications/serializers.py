from rest_framework import serializers
from .models import NotificationTemplate, Notification

class NotificationTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationTemplate
        fields = ['id', 'title', 'message', 'url', 'notification_type']

class NotificationSerializer(serializers.ModelSerializer):
    template = NotificationTemplateSerializer(read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'participant', 'template', 'is_read', 'created_at']
