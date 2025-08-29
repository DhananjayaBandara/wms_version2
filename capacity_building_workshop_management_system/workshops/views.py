from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Workshop, Session
from registrations.models import Registration
from users.models import Participant
from .serializers import WorkshopSerializer, SessionSerializer
from notifications.models import NotificationTemplate, Notification

@api_view(['GET'])
def list_workshops(request):
    workshops = Workshop.objects.all()
    serializer = WorkshopSerializer(workshops, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_workshop(request):
    """
    Creates a new workshop.
    """
    serializer = WorkshopSerializer(data=request.data)
    if serializer.is_valid():
        workshop = serializer.save()
        
        # Create or get the notification template
        template, created = NotificationTemplate.objects.get_or_create(
            title="New Workshop Added",
            defaults={
                'message': f"A new workshop '{workshop.title}' has been added.",
                'url': f"/workshops/{workshop.id}/",
                'notification_type': "workshop"
            }
        )
        
        # Create notifications for all participants
        for participant in Participant.objects.all():
            Notification.objects.create(
                participant=participant,
                template=template
            )
            
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def get_workshop_details(request, workshop_id):
    """
    Returns the details of the workshop with the given ID.
    """
    try:
        workshop = Workshop.objects.get(id=workshop_id)
        sessions = Session.objects.filter(workshop=workshop)
        participants = Registration.objects.filter(session__workshop=workshop).select_related('participant')

        workshop_data = {
            "id": workshop.id,
            "title": workshop.title,
            "description": workshop.description,
            "sessions": [
                {
                    "id": session.id,
                    "date": session.date,
                    "time": session.time,
                    "location": session.location,
                    "target_audience": session.target_audience,
                    "status": session.status,
                }
                for session in sessions
            ],
            "participants": [
                {
                    "id": reg.participant.id,
                    "name": reg.participant.name,
                    "email": reg.participant.email,
                    "contact_number": reg.participant.contact_number,
                    "nic": reg.participant.nic,
                    "district": reg.participant.district,
                    "gender": reg.participant.gender,
                }
                for reg in participants
            ],
        }
        return Response(workshop_data, status=status.HTTP_200_OK)
    except Workshop.DoesNotExist:
        return Response({"error": "Workshop not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['PUT'])
def update_workshop(request, workshop_id):
    """
    Updates the workshop with the given ID.
    """
    workshop = Workshop.objects.get(id=workshop_id)
    serializer = WorkshopSerializer(workshop, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_workshop(request, workshop_id):
    """
    Deletes the workshop with the given ID.
    """
    workshop = Workshop.objects.get(id=workshop_id)
    workshop.delete()
    return Response({"message": "Workshop deleted successfully."}, status=status.HTTP_200_OK)



# Session APIs

@api_view(['GET'])
def list_sessions(request):
    """
    Returns a list of all sessions.
    """
    sessions = Session.objects.all()
    serializer = SessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def get_sessions_by_workshop(request, workshop_id):
    """
    Returns a list of sessions for the given workshop.
    """
    sessions = Session.objects.filter(workshop_id=workshop_id)
    serializer = SessionSerializer(sessions, many=True)
    return Response(serializer.data)


@api_view(['POST'])
def get_sessions_by_ids(request):
    """
    Returns a list of sessions with the given IDs.
    """
    ids = request.data.get('ids', [])
    sessions = Session.objects.filter(id__in=ids)
    serializer = SessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def get_session_by_id(request, session_id):
    """
    Returns the session with the given ID.
    """
    session = Session.objects.get(id=session_id)
    serializer = SessionSerializer(session)
    return Response(serializer.data)

@api_view(['POST'])
def create_session(request):
    """
    Creates a new session.
    """
    serializer = SessionSerializer(data=request.data)
    if serializer.is_valid():
        session = serializer.save()
        # Create or get the notification template
        template, _ = NotificationTemplate.objects.get_or_create(
            title="New Session Added",
            message=f"A new session '{session}' has been added.",
            url=f"/workshops/sessions/{session.id}/",
            notification_type="session"
        )
        # Notify all participants
        for participant in Participant.objects.all():
            Notification.objects.create(
                participant=participant,
                template=template
            )
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_session(request, session_id):
    """
    Updates the session with the given ID.
    """
    session = Session.objects.get(id=session_id)
    serializer = SessionSerializer(session, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_session(request, session_id):
    """
    Deletes the session with the given ID.
    """
    session = Session.objects.get(id=session_id)
    session.delete()
    return Response({"message": "Session deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_emails_for_session(request, session_id):
    """
    Returns a list of emails of participants registered for the given session.
    """
    try:
        session = Session.objects.get(id=session_id)
        registrations = Registration.objects.filter(session=session).select_related('participant')
        emails = [reg.participant.email for reg in registrations]
        return Response({"emails": emails}, status=status.HTTP_200_OK)
    except Session.DoesNotExist:
        return Response({"error": "Session not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def get_all_participant_emails(request):
    """
    Returns a list of emails of all participants.
    """
    emails = Participant.objects.values_list('email', flat=True).distinct()
    return Response(list(emails))

