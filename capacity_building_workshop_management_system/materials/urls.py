from django.urls import path
from . import views

urlpatterns = [
    path('materials/sessions/<int:session_id>/', views.list_session_materials, name='list_session_materials'),
    path('materials/sessions/<int:session_id>/upload/', views.upload_session_material, name='upload_session_material'),
    path('materials/sessions/materials/<int:material_id>/delete/', views.delete_session_material, name='delete_session_material'),
]