from django.urls import path
from . import views

urlpatterns = [
    path('accounts/signup/', views.participant_signup, name='participant_signup'),
    path('accounts/signin/', views.participant_signin, name='participant_signin'),
    path('accounts/profile/<int:user_id>/', views.participant_profile, name='participant_profile'),
    path('accounts/profile/<int:user_id>/edit/', views.edit_participant_profile, name='edit_participant_profile'),
    path('accounts/change-password/', views.change_participant_password, name='change_participant_password'),
]