from django.db import models
from workshops.models import Session
from users.models import Participant

class FeedbackQuestion(models.Model):
    RESPONSE_TYPES = [
        ('paragraph', 'Paragraph'),
        ('checkbox', 'Checkbox'),
        ('rating', 'Rating'),
        ('text', 'Text'),
        ('multiple_choice', 'Multiple Choice'),
        ('yes_no', 'Yes/No'),
        ('scale', 'Scale'),
    ]

    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='feedback_questions')
    question_text = models.TextField()  # The feedback question itself
    response_type = models.CharField(max_length=20, choices=RESPONSE_TYPES)  # Type of response (e.g., paragraph, checkbox, rating)
    options = models.JSONField(null=True, blank=True)  # Store options for checkboxes or multiple-choice questions (JSON format)

    def __str__(self):
        return self.question_text


# Feedback Response Model
class FeedbackResponse(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='feedback_responses')
    question = models.ForeignKey(FeedbackQuestion, on_delete=models.CASCADE, related_name='responses')
    response = models.TextField()  # This will store the participant's response (it could be a text, JSON, rating, etc.)

    def __str__(self):
        return f"Response from {self.participant} to {self.question.question_text}"


# This model aggregates feedback from multiple participants into a session summary. It can be used for easy retrieval of feedback summaries for analysis and reports.
class SessionFeedback(models.Model):
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='session_feedback')
    total_responses = models.PositiveIntegerField(default=0)  # Track how many participants have provided feedback
    average_rating = models.FloatField(null=True, blank=True)  # Calculate and store average rating for the session if feedback includes ratings

    def update_feedback_summary(self):
        """Method to update the feedback summary (e.g., average rating, response count)"""
        feedback_responses = FeedbackResponse.objects.filter(question__session=self.session)
        total_ratings = 0
        rating_count = 0

        for response in feedback_responses:
            if response.question.response_type == 'rating':
                total_ratings += float(response.response)
                rating_count += 1

        self.total_responses = feedback_responses.count()
        self.average_rating = total_ratings / rating_count if rating_count > 0 else None
        self.save()

    def __str__(self):
        return f"Feedback for session {self.session.id}"


# This model can store reminders for participants to fill out feedback after a session. This will help in managing follow-up reminders (e.g., email).

class ParticipantFeedbackReminder(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='feedback_reminders')
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='feedback_reminders')
    reminder_sent = models.BooleanField(default=False)  # Whether the reminder has been sent
    reminder_sent_at = models.DateTimeField(null=True, blank=True)  # When the reminder was sent

    def send_reminder(self):
        # Logic to send an email or notification reminder to the participant to fill feedback.
        pass

    def __str__(self):
        return f"Reminder for {self.participant} to fill feedback for session {self.session.id}"


