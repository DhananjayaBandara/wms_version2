from django.urls import path
from . import views

urlpatterns = [
    path('questions/create/', views.create_feedback_question, name='create_feedback_question'),
    path('questions/<int:session_id>/', views.list_feedback_questions, name='list_feedback_questions'),
    path('responses/submit/', views.submit_feedback_response, name='submit_feedback_response'),
    path('responses/<int:session_id>/', views.list_feedback_responses, name='list_feedback_responses'),
    path('analysis/<int:session_id>/', views.feedback_analysis, name='feedback_analysis'),
    path('session-analysis/<int:session_id>/', views.session_feedback_analysis, name='session_feedback_analysis'),
]