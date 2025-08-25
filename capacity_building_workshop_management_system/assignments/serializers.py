from rest_framework import serializers
from .models import TrainerSession
from trainers.models import Trainer
from workshops.models import Session
from trainers.serializers import TrainerSerializer
from workshops.serializers import SessionSerializer

class TrainerSessionSerializer(serializers.ModelSerializer):
    trainer_id = serializers.PrimaryKeyRelatedField(
        queryset=Trainer.objects.all(),
        source='trainer',
        write_only=True
    )
    session_id = serializers.PrimaryKeyRelatedField(
        queryset=Session.objects.all(),
        source='session',
        write_only=True
    )
    trainer = TrainerSerializer(read_only=True)
    session = SessionSerializer(read_only=True)

    class Meta:
        model = TrainerSession
        fields = '__all__'
        