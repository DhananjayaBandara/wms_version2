from rest_framework import serializers
from .models import SessionMaterial

class SessionMaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionMaterial
        fields = ['id', 'session', 'url', 'uploaded_by', 'description']

    def validate(self, data):
        if not data.get('url'):
            raise serializers.ValidationError("URL is required.")
        return data
