from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from users.models import Participant
from trainers.models import Trainer

class UserAuth(models.Model):
    participant = models.OneToOneField(Participant, on_delete=models.CASCADE, related_name='auth')
    nic = models.CharField(max_length=20, unique=True)
    password = models.CharField(max_length=128)  # Store hashed password

    def set_password(self, raw_password):
        self.password = make_password(raw_password)
        self.save()

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)

    def __str__(self):
        return f"Auth for {self.nic}"


