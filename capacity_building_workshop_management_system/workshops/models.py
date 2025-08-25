from django.db import models
import uuid

class Workshop(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()

    def __str__(self):
        return self.title


# Session Model
class Session(models.Model):
    workshop = models.ForeignKey(Workshop, on_delete=models.CASCADE, related_name='sessions')
    date = models.DateField()
    time = models.TimeField()
    location = models.CharField(max_length=255)
    target_audience = models.CharField(max_length=255)
    token = models.UUIDField(unique=True, default=uuid.uuid4, editable=False)  # Unique token for each session
    status = models.CharField(max_length=20, choices=[('Upcoming', 'Upcoming'), ('Completed', 'Completed'), ('Cancelled', 'Cancelled'),('Ongoing', 'Ongoing'),('Postponed', 'Postponed')], default='Upcoming')

    def __str__(self):
        return f"{self.workshop.title} - {self.date}"

    def get_session_url(self):
        from django.conf import settings
        return f"{settings.FRONTEND_BASE_URL}/session/{self.token}/attendance"


