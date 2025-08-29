from django.urls import path
from . import views

urlpatterns = [
    path('sessions/<int:session_id>/questions/', views.list_session_questions, name='list_session_questions'),
    path('questions/<int:question_id>/mark-answered/', views.mark_question_answered, name='mark_question_answered'),
    path('participants/<int:participant_id>/questions/', views.participant_questions, name='participant_questions'),
    path('trainers/<int:trainer_id>/questions/', views.trainer_questions, name='trainer_questions'),
    path('questions/submit/', views.submit_question, name='submit_question'),
]