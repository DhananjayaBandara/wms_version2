from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_participant_types, name='list_participant_types'),
    path('create/', views.create_participant_type, name='create_participant_type'),
    path('<int:type_id>/update/', views.update_participant_type, name='update_participant_type'),
    path('<int:type_id>/delete/', views.delete_participant_type, name='delete_participant_type'),
    path('<int:type_id>/required-fields/', views.get_required_fields_for_participant_type, name='get_required_fields'),
]