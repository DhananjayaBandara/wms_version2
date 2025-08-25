from django.urls import path
from . import views

urlpatterns = [
    path('users/', views.list_participants, name='list_participants'),
    path('users/register/', views.register_participant, name='register_participant'),
    path('users/<int:participant_id>/delete/', views.delete_participant, name='delete_participant'),
    path('users/nic/<str:nic>/', views.get_participant_by_nic, name='get_participant_by_nic'),
    path('users/batch/', views.get_participants_by_ids, name='get_participants_by_ids'),
    path('users/<int:participant_id>/sessions/', views.participant_sessions_info, name='participant_sessions_info'),
]