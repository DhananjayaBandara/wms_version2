from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_workshops, name='list_workshops'),
    path('create/', views.create_workshop, name='create_workshop'),
    path('<int:workshop_id>/', views.get_workshop_details, name='get_workshop_details'),
    path('<int:workshop_id>/update/', views.update_workshop, name='update_workshop'),
    path('<int:workshop_id>/delete/', views.delete_workshop, name='delete_workshop'),
    path('sessions/', views.list_sessions, name='list_sessions'),
    path('sessions/create/', views.create_session, name='create_session'),
    path('sessions/<int:session_id>/update/', views.update_session, name='update_session'),
    path('sessions/<int:session_id>/delete/', views.delete_session, name='delete_session'),
    path('<int:workshop_id>/sessions/', views.get_sessions_by_workshop, name='get_sessions_by_workshop'),
    path('sessions/batch/', views.get_sessions_by_ids, name='get_sessions_by_ids'),  
    path('sessions/<int:session_id>/emails/', views.get_emails_for_session, name='get_emails_for_session'),
    path('participants/emails/', views.get_all_participant_emails, name='get_all_participant_emails'),
    path('sessions/<int:session_id>/', views.get_session_by_id, name='get_session_by_id'),
]