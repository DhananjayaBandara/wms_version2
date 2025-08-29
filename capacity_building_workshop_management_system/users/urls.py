from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_participants, name='list_participants'),
    path('register/', views.register_participant, name='register_participant'),
    path('<int:participant_id>/delete/', views.delete_participant, name='delete_participant'),
    path('nic/<str:nic>/', views.get_participant_by_nic, name='get_participant_by_nic'),
    path('batch/', views.get_participants_by_ids, name='get_participants_by_ids'),
    path('<int:participant_id>/sessions/', views.participant_sessions_info, name='participant_sessions_info'),
]