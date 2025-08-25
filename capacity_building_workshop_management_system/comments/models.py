from django.db import models
from workshops.models import Session

class AdminComment(models.Model):
    """
    Model to store comments made by admins for each session.
    Comments can include impact, special facts, improvements, etc.
    """

    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='admin_comments')
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Admin Comment'
        verbose_name_plural = 'Admin Comments'

    def __str__(self):
        return f"{self.session} ({self.created_at.strftime('%Y-%m-%d')})"

