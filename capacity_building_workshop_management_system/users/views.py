from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Participant
from .serializers import ParticipantSerializer
from django.shortcuts import get_object_or_404
from registrations.models import Registration

@api_view(['GET'])
def list_participants(request):
    participants = Participant.objects.all()
    serializer = ParticipantSerializer(participants, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def register_participant(request):
    serializer = ParticipantSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_participant(request, participant_id):
    participant = get_object_or_404(Participant, id=participant_id)
    participant.delete()
    return Response({"message": "Participant deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_participant_by_nic(request, nic):
    try:
        participant = Participant.objects.get(nic=nic)
        serializer = ParticipantSerializer(participant)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Participant.DoesNotExist:
        return Response({"error": "Participant not found."}, status=status.HTTP_404_NOT_FOUND)
        
@api_view(['POST'])
def get_participants_by_ids(request):
    ids = request.data.get('ids', [])
    participants = Participant.objects.filter(id__in=ids)
    serializer = ParticipantSerializer(participants, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def participant_sessions_info(request, participant_id):

    registrations = Registration.objects.filter(participant_id=participant_id).select_related('session', 'session__workshop')
    sessions = []
    attended_sessions = []
    for reg in registrations:
        session = reg.session
        session_info = {
            "id": session.id,
            "workshop_title": session.workshop.title if session.workshop else "",
            "date_time": session.date_time,
            "attended": reg.attendance,
        }
        sessions.append(session_info)
        if reg.attendance:
            attended_sessions.append(session_info)

    return Response({
        "registered_count": len(sessions),
        "attended_count": len(attended_sessions),
        "sessions": sessions,
        "attended_sessions": attended_sessions,
    })
