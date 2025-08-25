from rest_framework import serializers
from .models import Question
from users.models import Participant
from workshops.models import Session
from registrations.models import Registration

class QuestionSerializer(serializers.ModelSerializer):
    """
    Serializer for handling Q&A questions.
    """
    participant = serializers.PrimaryKeyRelatedField(
        queryset=Participant.objects.all(),
        required=True
    )
    session = serializers.PrimaryKeyRelatedField(
        queryset=Session.objects.all(),
        required=True
    )
    participant_name = serializers.CharField(source='participant.name', read_only=True)
    created_at_formatted = serializers.DateTimeField(
        source='created_at', 
        format='%Y-%m-%d %H:%M',
        read_only=True
    )

    class Meta:
        model = Question
        fields = [
            'id', 'session', 'participant', 'question_text', 'is_answered',
            'created_at', 'created_at_formatted', 'participant_name'
        ]
        read_only_fields = ['is_answered', 'created_at']

    def validate(self, data):
        """
        Validate that the participant is registered for the session.
        """
        participant = data.get('participant')
        session = data.get('session')
        
        # Check if participant is registered for the session
        if not Registration.objects.filter(
            participant=participant,
            session=session
        ).exists():
            raise serializers.ValidationError(
                "Participant is not registered for this session."
            )
        
        return data
