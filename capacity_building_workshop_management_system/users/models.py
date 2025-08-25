from django.db import models
from user_types.models import ParticipantType

class Participant(models.Model):
    name = models.CharField(max_length=150, default='Unknown')  # Add default here
    email = models.EmailField(unique=True)
    contact_number = models.CharField(max_length=20)
    nic = models.CharField(max_length=20,unique=True)
    district = models.CharField(max_length=100)
    gender = models.CharField(max_length=10, choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')])
    participant_type = models.ForeignKey(ParticipantType, on_delete=models.SET_NULL, null=True)
    properties = models.JSONField(default=dict)

    def __str__(self):
        return self.name
