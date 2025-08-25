from rest_framework import serializers
from .models import ParticipantType

class ParticipantTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParticipantType
        fields = '__all__'