from django.urls import path
from . import views

urlpatterns = [
    path('sessions/<int:session_id>/submit/', views.submit_admin_comment, name='submit_admin_comment'),
    path('sessions/<int:session_id>/update/', views.update_admin_comment, name='update_admin_comment'),
    path('sessions/<int:session_id>/', views.get_admin_comments, name='get_admin_comments'),
    path('workshops/<int:workshop_id>/', views.get_workshop_admin_comments, name='get_workshop_admin_comments'),
]