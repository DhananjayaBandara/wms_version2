from rest_framework import serializers
from workshops.models import Session

class TrainerDashboardSerializer(serializers.Serializer):
    session_id = serializers.IntegerField()
    session_title = serializers.CharField()
    date = serializers.DateField()
    time = serializers.TimeField()
    workshop_title = serializers.CharField()
    location = serializers.CharField()
    total_participants = serializers.IntegerField()
    attendance_count = serializers.IntegerField()
    average_rating = serializers.FloatField(allow_null=True)
    
    formatted_date = serializers.SerializerMethodField()
    formatted_time = serializers.SerializerMethodField()

    def get_formatted_date(self, obj):
        return obj.date.strftime('%A, %d %B %Y')

    def get_formatted_time(self, obj):
        return obj.time.strftime('%I:%M %p')
