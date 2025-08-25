from django.db import models
from django.contrib.auth.hashers import make_password, check_password

class Trainer(models.Model):
    name = models.CharField(max_length=255)
    designation = models.CharField(max_length=255)
    email = models.EmailField()
    contact_number = models.CharField(max_length=20)
    expertise = models.TextField()

    def __str__(self):
        return self.name


class TrainerCredential(models.Model):
    trainer = models.OneToOneField('Trainer', on_delete=models.CASCADE, related_name='credential')
    username = models.CharField(max_length=150, unique=True)
    password = models.CharField(max_length=128)  # Store hashed password

    def set_password(self, raw_password):
        self.password = make_password(raw_password)
        self.save(update_fields=['password'])

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)

    def __str__(self):
        return f"Credential for {self.trainer.name} ({self.username})"
