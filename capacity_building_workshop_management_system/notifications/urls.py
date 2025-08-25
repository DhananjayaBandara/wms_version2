from django.urls import path
from . import views

urlpatterns = [
    path('notifications/participants/<int:participant_id>/', views.list_notifications, name='list_notifications'),
    path('notifications/<int:notification_id>/mark-read/', views.mark_notification_read, name='mark_notification_read'),
    path('notifications/send/', views.send_notification, name='send_notification'),
]