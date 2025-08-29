from django.urls import path
from . import views

urlpatterns = [
    path('dashboard/trainer/<int:trainer_id>/', views.trainer_dashboard, name='trainer_dashboard'),
    path('dashboard/admin/counts/', views.admin_dashboard_counts, name='admin_dashboard_counts'),
    path('sessions/<int:session_id>/dashboard/', views.session_statistics_dashboard, name='session_statistics_dashboard'),
    path('sessions/', views.analytics_sessions, name='analytics_sessions'),
    path('workshops/', views.analytics_workshops, name='analytics_workshops'),
    path('trainers/', views.analytics_trainers, name='analytics_trainers'),
    path('participants/', views.analytics_participants, name='analytics_participants'),
    path('sessions-overview/', views.analytics_sessions_overview, name='analytics_sessions_overview'),
    path('sessions/list/', views.analytics_sessions_list, name='analytics_sessions_list'),
    path('sessions/<int:session_id>/detail/', views.analytics_session_detail, name='analytics_session_detail'),
    path('workshops-overview/', views.analytics_workshops_overview, name='analytics_workshops_overview'),
    path('workshops/list/', views.analytics_workshops_list, name='analytics_workshops_list'),
    path('workshops/<int:workshop_id>/detail/', views.analytics_workshop_detail, name='analytics_workshop_detail'),
    path('trainers/<int:trainer_id>/detail/', views.analytics_trainer_detail, name='analytics_trainer_detail'),
    path('participants-overview/', views.analytics_participants_overview, name='analytics_participants_overview'),
    path('reports/sessions-overview/', views.sessions_report_overview, name='sessions_report_overview'),
]