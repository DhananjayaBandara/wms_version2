from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import Registration
from .serializers import RegistrationSerializer
from workshops.models import Session
from users.models import Participant

@api_view(['POST'])
def register_for_session(request):
    """
    Register a participant for a session.
    Expects: { "participant": "...", "session": "..." }
    """
    participant_id = request.data.get('participant')
    session_id = request.data.get('session')
    # Check for existing registration
    if Registration.objects.filter(participant_id=participant_id, session_id=session_id).exists():
        return Response(
            {"error": "Participant is already registered for this session."},
            status=status.HTTP_400_BAD_REQUEST
        )
    serializer = RegistrationSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def cancel_registration(request):
    """
    Cancel a participant's registration for a session.
    Expects: { "participant": "...", "session": "..." }
    """
    participant_id = request.data.get('participant')
    session_id = request.data.get('session')
    
    if not participant_id or not session_id:
        return Response(
            {"error": "Both participant ID and session ID are required."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        registration = Registration.objects.get(
            participant_id=participant_id,
            session_id=session_id
        )
        registration.delete()
        return Response(
            {"message": "Registration cancelled successfully."},
            status=status.HTTP_200_OK
        )
    except Registration.DoesNotExist:
        return Response(
            {"error": "No registration found for this participant and session."},
            status=status.HTTP_404_NOT_FOUND
        )


# Mark Attendance API (for QR scanning)
@api_view(['POST'])
def mark_attendance(request):
    """
    Mark attendance for a participant.
    Expects: { "registration_id": "..." }
    """
    try:
        registration_id = request.data.get('registration_id')
        registration = Registration.objects.get(id=registration_id)
        registration.attendance = True
        registration.save()
        return Response({"message": "Attendance marked successfully!"}, status=status.HTTP_200_OK)
    except Registration.DoesNotExist:
        return Response({"error": "Invalid registration ID"}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def mark_attendance_by_token(request, token):
    """
    Mark attendance for a participant using their NIC and session token.
    Expects: { "nic": "..." }
    """
    nic = request.data.get('nic')
    if not nic:
        return Response({"error": "NIC is required."}, status=status.HTTP_400_BAD_REQUEST)

    session = get_object_or_404(Session, token=token)
    participant = get_object_or_404(Participant, nic=nic)
    registration = Registration.objects.filter(session=session, participant=participant).first()

    if not registration:
        return Response({"error": "Participant is not registered for this session."}, status=status.HTTP_400_BAD_REQUEST)

    registration.attendance = True
    registration.save()

    return Response({"message": "Attendance marked successfully."}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def mark_attendance_qr(request):
    """
    Mark attendance for a participant using a QR code.
    
    Accepts:
    - session_token: str (required)
    - participant_id: int (required)
    
    Returns:
    - status: str (success/error/not_registered/already_marked)
    - message: str (description of the result)
    """
    session_token = request.data.get('session_token')
    participant_id = request.data.get('participant_id')

    if not session_token or not participant_id:
        return Response({"status": "error", "message": "Missing session token or participant ID."}, status=400)

    try:
        session = Session.objects.get(token=session_token)
        participant = Participant.objects.get(id=participant_id)
    except Session.DoesNotExist:
        return Response({"status": "error", "message": "Invalid session token."}, status=404)
    except Participant.DoesNotExist:
        return Response({"status": "error", "message": "Invalid participant ID."}, status=404)

    try:
        registration = Registration.objects.get(session=session, participant=participant)
    except Registration.DoesNotExist:
        return Response({"status": "not_registered", "message": "You are not registered for this session."}, status=403)

    if registration.attendance:
        return Response({"status": "already_marked", "message": "Attendance has already been marked for this session."}, status=200)

    registration.attendance = True
    registration.save(update_fields=['attendance'])
    return Response({"status": "success", "message": "Attendance marked successfully."}, status=200)

@api_view(['POST'])
def register_session_for_participant(request, user_id):
    """
    Register a participant for a session.
    Expects: { "session_id": "..." }
    """
    session_id = request.data.get('session_id')
    if not session_id:
        return Response({'success': False, 'message': 'Session ID is required.'}, status=400)
    try:
        participant = Participant.objects.get(id=user_id)
    except Participant.DoesNotExist:
        return Response({'success': False, 'message': 'Participant not found.'}, status=404)
    try:
        session = Session.objects.get(id=session_id)
    except Session.DoesNotExist:
        return Response({'success': False, 'message': 'Session not found.'}, status=404)
    # Check if already registered
    if Registration.objects.filter(participant=participant, session=session).exists():
        return Response({'success': False, 'message': 'Already registered for this session.'}, status=400)
    # Register
    Registration.objects.create(participant=participant, session=session)
    return Response({'success': True, 'message': 'Successfully registered for the session.'}, status=200)

@api_view(['GET'])
def participant_registered_sessions(request, participant_id):
    """Return all sessions the participant has registered for (without materials field)."""
    registrations = Registration.objects.filter(participant_id=participant_id)
    sessions = Session.objects.filter(id__in=registrations.values_list('session_id', flat=True))
    serializer = SessionNoMaterialsSerializer(sessions, many=True)
    return Response(serializer.data)
@api_view(['GET'])
def participant_attended_sessions(request, participant_id):
    """Return all sessions the participant has attended."""
    registrations = Registration.objects.filter(participant_id=participant_id, attendance=True)
    sessions = Session.objects.filter(id__in=registrations.values_list('session_id', flat=True))
    serializer = SessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def participant_feedback_submitted_sessions(request, participant_id):
    """Return all sessions where the participant has submitted feedback, including their responses."""
    feedback_responses = FeedbackResponse.objects.filter(participant_id=participant_id)
    session_ids = feedback_responses.values_list('question__session_id', flat=True).distinct()
    sessions = Session.objects.filter(id__in=session_ids)
    session_data = []
    for session in sessions:
        responses = feedback_responses.filter(question__session=session)
        session_serialized = SessionSerializer(session).data
        session_serialized['feedback_responses'] = FeedbackResponseSerializer(responses, many=True).data
        session_data.append(session_serialized)
    return Response(session_data)

@api_view(['GET'])
def session_participant_counts(request, session_id):
    """Return the count of registered and attended participants for a session."""
    from .models import Registration
    from .serializers import ParticipantSerializer

    registrations = Registration.objects.filter(session_id=session_id).select_related('participant')
    registered_participants = [reg.participant for reg in registrations]
    attended_participants = [reg.participant for reg in registrations if reg.attendance]

    registered_serializer = ParticipantSerializer(registered_participants, many=True)
    attended_serializer = ParticipantSerializer(attended_participants, many=True)

    return Response({
        "registered_count": len(registered_participants),
        "registered_participants": registered_serializer.data,
        "attended_count": len(attended_participants),
        "attended_participants": attended_serializer.data,
    })
