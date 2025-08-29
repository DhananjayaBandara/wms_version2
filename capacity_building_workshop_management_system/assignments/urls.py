from django.urls import path
from . import views

urlpatterns = [
    path('trainers/sessions/assign/', views.assign_trainer_to_session, name='assign_trainer_to_session'),
    path('trainers/sessions/remove/', views.remove_trainer_from_session, name='remove_trainer_from_session'),
]