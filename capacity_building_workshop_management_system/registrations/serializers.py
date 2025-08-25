from rest_framework import serializers
from .models import Registration
from users.models import Participant
from workshops.models import Session
from users.serializers import ParticipantSerializer
from workshops.serializers import SessionSerializer

class RegistrationSerializer(serializers.ModelSerializer):
    participant = ParticipantSerializer(read_only=True)
    participant_id = serializers.PrimaryKeyRelatedField(
        queryset=Participant.objects.all(),
        source='participant',
        write_only=True
    )

    session = SessionSerializer(read_only=True)
    session_id = serializers.PrimaryKeyRelatedField(
        queryset=Session.objects.all(),
        source='session',
        write_only=True
    )

    class Meta:
        model = Registration
        fields = [
            'id', 'participant', 'participant_id', 'session', 'session_id',
            'registered_on', 'attendance'
        ]
