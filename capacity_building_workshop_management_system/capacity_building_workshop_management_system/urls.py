"""
URL configuration for capacity_building_workshop_management_system project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('accounts/', include('accounts.urls')),
    path('users/', include('users.urls')),
    path('trainers/', include('trainers.urls')),
    path('user_types/', include('user_types.urls')),
    path('workshops/', include('workshops.urls')),
    path('assignments/', include('assignments.urls')),
    path('registrations/', include('registrations.urls')),
    path('feedback/', include('feedback.urls')),
    path('qa/', include('qa.urls')),
    path('materials/', include('materials.urls')),
    path('notifications/', include('notifications.urls')),
    path('analytics/', include('analytics.urls')),
    path('comments/', include('comments.urls')),
]