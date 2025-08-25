from rest_framework import serializers
from .models import Workshop, Session
from assignments.models import TrainerSession
from materials.serializers import SessionMaterialSerializer

class WorkshopSerializer(serializers.ModelSerializer):
    class Meta:
        model = Workshop
        fields = '__all__'

class SessionSerializer(serializers.ModelSerializer):
    workshop_id = serializers.PrimaryKeyRelatedField(
        queryset=Workshop.objects.all(),
        source='workshop',
        write_only=True
    )
    workshop = WorkshopSerializer(read_only=True)
    trainers = serializers.SerializerMethodField()
    token = serializers.UUIDField(read_only=True)
    materials = SessionMaterialSerializer(many=True, read_only=True)
    
    formatted_date = serializers.SerializerMethodField()
    formatted_time = serializers.SerializerMethodField()

    class Meta:
        model = Session
        fields = [
            'id', 'workshop', 'workshop_id', 'date', 'time', 'formatted_date', 'formatted_time','status',
            'location', 'target_audience', 'trainers', 'token','materials'
        ]

    def get_trainers(self, obj):
        trainer_sessions = TrainerSession.objects.filter(session=obj)
        return [
            {"id": ts.trainer.id, "name": ts.trainer.name}
            for ts in trainer_sessions
        ]

    def get_formatted_date(self, obj):
        return obj.date.strftime('%A, %d %B %Y')  # e.g., Wednesday, 18 June 2025

    def get_formatted_time(self, obj):
        return obj.time.strftime('%I:%M %p')  # e.g., 11:55 AM
