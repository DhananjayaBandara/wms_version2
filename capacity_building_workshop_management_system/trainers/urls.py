from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_trainers, name='list_trainers'),
    path('create/', views.create_trainer, name='create_trainer'),
    path('<int:trainer_id>/update/', views.update_trainer, name='update_trainer'),
    path('<int:trainer_id>/delete/', views.delete_trainer, name='delete_trainer'),
    path('<int:trainer_id>/details/', views.get_trainer_details, name='get_trainer_details'),
    path('login/', views.trainer_login, name='trainer_login'),
    path('<int:trainer_id>/credential/create/', views.create_trainer_credential, name='create_trainer_credential'),
    path('<int:trainer_id>/credential/update/', views.update_trainer_credential, name='update_trainer_credential'),
]