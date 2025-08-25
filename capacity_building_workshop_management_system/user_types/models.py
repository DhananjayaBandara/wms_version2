from django.db import models


class ParticipantType(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    properties = models.JSONField(default=dict)

    def __str__(self):
        return self.name

