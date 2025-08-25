from django.db import models
from workshops.models import Session

class SessionStatistics(models.Model):
    session = models.OneToOneField(Session, on_delete=models.CASCADE, related_name='statistics')
    registered_count = models.PositiveIntegerField(default=0)
    attended_count = models.PositiveIntegerField(default=0)
    attendance_percentage = models.FloatField(default=0.0)
    average_rating = models.FloatField(null=True, blank=True)
    impact_summary = models.TextField(blank=True, null=True)
    improvement_suggestions = models.JSONField(default=list, blank=True)

    def __str__(self):
        return f"Statistics for session {self.session.id}"


