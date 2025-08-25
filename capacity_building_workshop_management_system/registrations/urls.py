from django.urls import path
from . import views
from .views import mark_attendance_by_token

urlpatterns = [
    path('registrations/', views.register_for_session, name='register_for_session'),
    path('registrations/cancel/', views.cancel_registration, name='cancel_registration'),
    path('registrations/attendance/mark/', views.mark_attendance, name='mark_attendance'),
    path('registrations/attendance/qr/', views.mark_attendance_qr, name='mark_attendance_qr'),
    path('registrations/sessions/<str:token>/attendance/', mark_attendance_by_token, name='mark_attendance_by_token'),
    path('registrations/participants/<int:user_id>/register-session/', views.register_session_for_participant, name='register_session_for_participant'),
    path('registrations/participants/<int:participant_id>/registered-sessions/', views.participant_registered_sessions, name='participant_registered_sessions'),
    path('registrations/participants/<int:participant_id>/attended-sessions/', views.participant_attended_sessions, name='participant_attended_sessions'),
    path('registrations/participants/<int:participant_id>/feedback-sessions/', views.participant_feedback_submitted_sessions, name='participant_feedback_submitted_sessions'),
    path('registrations/sessions/<int:session_id>/participants/', views.session_participant_counts, name='session_participant_counts'),
]