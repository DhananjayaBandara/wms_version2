from django.db import models
from workshops.models import Session
from users.models import Participant
from django.utils import timezone

class Question(models.Model):
    """
    Model to store questions asked by participants during Q&A sessions.
    """
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='questions')
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='questions_asked')
    question_text = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)
    is_answered = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['session', 'is_answered']),
            models.Index(fields=['participant']),
            models.Index(fields=['created_at']),
        ]

    def mark_as_answered(self):
        """Mark the question as answered with the current timestamp."""
        if not self.is_answered:
            self.is_answered = True
            self.save(update_fields=['is_answered'])

    def __str__(self):
        return f"Q: {self.question_text[:50]}... (Session: {self.session.id}, Answered: {self.is_answered})"
