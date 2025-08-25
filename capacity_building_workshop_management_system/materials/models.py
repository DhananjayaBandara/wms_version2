from django.db import models
from workshops.models import Session
from trainers.models import Trainer

class SessionMaterial(models.Model):
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='materials')
    url = models.URLField(blank=True, null=True)  # For links, drive, etc.
    uploaded_by = models.ForeignKey(Trainer, on_delete=models.SET_NULL, null=True, blank=True)
    description = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Material for session {self.session.id}"


