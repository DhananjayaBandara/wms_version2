from django.db import models
from users.models import Participant

class NotificationTemplate(models.Model):
    title = models.CharField(max_length=255)
    message = models.TextField()
    url = models.URLField(blank=True, null=True)
    notification_type = models.CharField(max_length=50, default='general')

    def __str__(self):
        return self.title


class Notification(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='notifications')
    template = models.ForeignKey(NotificationTemplate, on_delete=models.CASCADE, related_name='notifications', default=None)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.participant.name} - {'Read' if self.is_read else 'Unread'}"

