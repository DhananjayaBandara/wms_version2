from django.urls import path
from . import views

urlpatterns = [
    path('feedback/questions/create/', views.create_feedback_question, name='create_feedback_question'),
    path('feedback/questions/<int:session_id>/', views.list_feedback_questions, name='list_feedback_questions'),
    path('feedback/responses/submit/', views.submit_feedback_response, name='submit_feedback_response'),
    path('feedback/responses/<int:session_id>/', views.list_feedback_responses, name='list_feedback_responses'),
    path('feedback/analysis/<int:session_id>/', views.feedback_analysis, name='feedback_analysis'),
    path('feedback/session-analysis/<int:session_id>/', views.session_feedback_analysis, name='session_feedback_analysis'),
]