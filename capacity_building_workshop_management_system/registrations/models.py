from django.db import models
from users.models import Participant
from workshops.models import Session

class Registration(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='registrations')
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='registrations')
    registered_on = models.DateTimeField(auto_now_add=True)
    attendance = models.BooleanField(default=False)

    class Meta:
        unique_together = ('participant', 'session')

    def __str__(self):
        return f"{self.participant} - {self.session}"

