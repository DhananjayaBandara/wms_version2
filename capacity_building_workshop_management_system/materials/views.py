from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from workshops.models import Session
from registrations.models import Registration
from notifications.models import Notification, NotificationTemplate
from trainers.models import Trainer
from .models import SessionMaterial
from .serializers import SessionMaterialSerializer
from workshops.serializers import SessionSerializer
from rest_framework import status
from django.shortcuts import get_object_or_404  
from assignments.models import TrainerSession
from users.models import Participant

@api_view(['GET'])
def list_session_materials(request, session_id):
    """List all materials for a session (for attended participants)."""
    materials = SessionMaterial.objects.filter(session_id=session_id)
    serializer = SessionMaterialSerializer(materials, many=True)
    return Response(serializer.data)


@api_view(['POST'])
def upload_session_material(request, session_id):
    """Upload a new material for a session."""
    session = get_object_or_404(Session, id=session_id)
    trainer_id = request.data.get('uploaded_by')
    if not TrainerSession.objects.filter(session=session, trainer_id=trainer_id).exists():
        return Response({'error': 'Only trainers of this session can upload materials.'}, status=403)
    data = request.data.copy()
    data['session'] = session.id
    serializer = SessionMaterialSerializer(data=data)
    if serializer.is_valid():
        material = serializer.save()
        # Create or get the notification template
        template, _ = NotificationTemplate.objects.get_or_create(
            title="New Session Material",
            message=f"New material has been uploaded for your session '{session}'.",
            url=f"/sessions/{session.id}/materials/",
            notification_type="material"
        )
        # Notify attended participants
        attended_regs = Registration.objects.filter(session=session, attendance=True)
        for reg in attended_regs:
            Notification.objects.create(
                participant=reg.participant,
                template=template
            )
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)

@api_view(['DELETE'])
def delete_session_material(request, material_id):
    """Delete a material by its ID."""
    try:
        material = SessionMaterial.objects.get(id=material_id)
        material.delete()
        return Response({'message': 'Material deleted.'}, status=200)
    except SessionMaterial.DoesNotExist:
        return Response({'error': 'Material not found.'}, status=404)
    
class SessionNoMaterialsSerializer(SessionSerializer):
    class Meta(SessionSerializer.Meta):
        exclude = []
        fields = [f for f in SessionSerializer.Meta.fields if f != 'materials']

