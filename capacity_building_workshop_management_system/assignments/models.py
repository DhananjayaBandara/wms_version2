from django.db import models
from trainers.models import Trainer
from workshops.models import Session

class TrainerSession(models.Model):
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE)
    session = models.ForeignKey(Session, on_delete=models.CASCADE)

    class Meta:
        unique_together = ('trainer', 'session')

    def __str__(self):
        return f"{self.trainer.name} - {self.session}"


