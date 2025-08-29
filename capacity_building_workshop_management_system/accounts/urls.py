from django.urls import path
from . import views

urlpatterns = [
    path('signup/', views.participant_signup, name='participant_signup'),
    path('signin/', views.participant_signin, name='participant_signin'),
    path('profile/<int:user_id>/', views.participant_profile, name='participant_profile'),
    path('profile/<int:user_id>/edit/', views.edit_participant_profile, name='edit_participant_profile'),
    path('change-password/', views.change_participant_password, name='change_participant_password'),
]