from django.urls import path
from . import views
from .views import mark_attendance_by_token

urlpatterns = [
    path('', views.register_for_session, name='register_for_session'),
    path('cancel/', views.cancel_registration, name='cancel_registration'),
    path('attendance/mark/', views.mark_attendance, name='mark_attendance'),
    path('attendance/qr/', views.mark_attendance_qr, name='mark_attendance_qr'),
    path('sessions/<str:token>/attendance/', mark_attendance_by_token, name='mark_attendance_by_token'),
    path('<int:user_id>/register-session/', views.register_session_for_participant, name='register_session_for_participant'),
    path('<int:participant_id>/registered-sessions/', views.participant_registered_sessions, name='participant_registered_sessions'),
    path('<int:participant_id>/attended-sessions/', views.participant_attended_sessions, name='participant_attended_sessions'),
    path('<int:participant_id>/feedback-sessions/', views.participant_feedback_submitted_sessions, name='participant_feedback_submitted_sessions'),
    path('sessions/<int:session_id>/participants/', views.session_participant_counts, name='session_participant_counts'),
]