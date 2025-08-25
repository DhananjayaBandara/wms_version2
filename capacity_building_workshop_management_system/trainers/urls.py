from django.urls import path
from . import views

urlpatterns = [
    path('trainers/', views.list_trainers, name='list_trainers'),
    path('trainers/create/', views.create_trainer, name='create_trainer'),
    path('trainers/<int:trainer_id>/update/', views.update_trainer, name='update_trainer'),
    path('trainers/<int:trainer_id>/delete/', views.delete_trainer, name='delete_trainer'),
    path('trainers/<int:trainer_id>/details/', views.get_trainer_details, name='get_trainer_details'),
    path('trainers/login/', views.trainer_login, name='trainer_login'),
    path('trainers/<int:trainer_id>/credential/create/', views.create_trainer_credential, name='create_trainer_credential'),
    path('trainers/<int:trainer_id>/credential/update/', views.update_trainer_credential, name='update_trainer_credential'),
]