from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from users.models import Participant
from users.serializers import ParticipantSerializer
from .models import UserAuth
from trainers.models import Trainer
from trainers.serializers import TrainerSerializer
from workshops.models import Session
from registrations.models import Registration
from feedback.models import FeedbackQuestion, FeedbackResponse

@api_view(['POST'])
def participant_signup(request):
    """
    Sign up for a participant.
    Expects: { "nic": "...", "password": "...", "...": "..." }
    """
    nic = request.data.get('nic')
    password = request.data.get('password')

    # All participant fields are expected at the root level
    participant_data = request.data.copy()
    participant_data.pop('password', None)

    if not nic or not password:
        return Response({'error': 'NIC and password are required.'}, status=400)
    if UserAuth.objects.filter(nic=nic).exists():
        return Response({'error': 'User with this NIC already exists.'}, status=400)

    participant_serializer = ParticipantSerializer(data=participant_data)
    if participant_serializer.is_valid():
        participant = participant_serializer.save()
        user_auth = UserAuth(participant=participant, nic=nic)
        user_auth.set_password(password)
        user_auth.save()
        return Response({'message': 'Signup successful.'}, status=201)
    else:
        return Response(participant_serializer.errors, status=400)

@api_view(['POST'])
def participant_signin(request):
    """
    Sign in for a participant.
    Expects: { "nic": "...", "password": "..." }
    """
    nic = request.data.get('nic')
    password = request.data.get('password')
    try:
        user_auth = UserAuth.objects.get(nic=nic)
        if user_auth.check_password(password):
            return Response({'message': 'Sign in successful.', 'participant_id': user_auth.participant.id}, status=200)
        else:
            return Response({'error': 'Invalid credentials.'}, status=400)
    except UserAuth.DoesNotExist:
        return Response({'error': 'User not found.'}, status=404)

@api_view(['GET'])
def participant_profile(request, user_id):
    """
    Get participant profile.
    """
    try:
        participant = Participant.objects.get(id=user_id)
    except Participant.DoesNotExist:
        return Response({'error': 'Participant not found'}, status=404)

    participant_data = ParticipantSerializer(participant).data

    now = timezone.now()
    registrations = Registration.objects.filter(participant=participant)
    registered_session_ids = registrations.values_list('session_id', flat=True)
    attended_session_ids = registrations.filter(attendance=True).values_list('session_id', flat=True)

    all_sessions = Session.objects.all()
    registered_sessions= all_sessions.filter(id__in=registered_session_ids)
    upcoming_sessions = all_sessions.filter(date_time__gt=now)
    past_sessions = all_sessions.filter(date_time__lte=now)

    registered_upcoming = upcoming_sessions.filter(id__in=registered_session_ids)
    unregistered_upcoming = upcoming_sessions.exclude(id__in=registered_session_ids)
    registered_past = past_sessions.filter(id__in=registered_session_ids)
    attended_sessions = past_sessions.filter(id__in=attended_session_ids)

    # Feedback needed: past sessions where registered, attended, but no feedback
    feedback_needed = []
    for reg in registrations.filter(session__date_time__lte=now):
        if not reg.attendance:
            continue
        # Get all feedback questions for this session
        question_ids = FeedbackQuestion.objects.filter(session=reg.session).values_list('id', flat=True)
        if not FeedbackResponse.objects.filter(participant=participant, question_id__in=question_ids).exists():
            feedback_needed.append(reg.session.id)

    def session_list(qs):
        return [
            {
                'id': s.id,
                'title': str(s),
                'date_time': s.date_time.isoformat(),
                'location': getattr(s, 'location', ''),
            }
            for s in qs
        ]

    return Response({
        'participant': participant_data,
        'registered_session': session_list(registered_sessions),
        'upcoming_sessions': session_list(upcoming_sessions),
        'registered_upcoming_sessions': session_list(registered_upcoming),
        'unregistered_upcoming_sessions': session_list(unregistered_upcoming),
        'past_sessions': session_list(past_sessions),
        'registered_past_sessions': session_list(registered_past),
        'attended_sessions': session_list(attended_sessions),
        'feedback_needed_sessions': session_list(Session.objects.filter(id__in=feedback_needed)),
    })
    
@api_view(['PUT'])
def edit_participant_profile(request, user_id):
    """
    Edit participant profile.
    Expects: { "...": "..." }
    """
    try:
        participant = Participant.objects.get(id=user_id)
    except Participant.DoesNotExist:
        return Response({'error': 'Participant not found'}, status=404)

    serializer = ParticipantSerializer(participant, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=200)
    else:
        return Response(serializer.errors, status=400)

@api_view(['POST'])
def change_participant_password(request):
    """
    Change password for a participant.
    Expects: { "nic": "...", "current_password": "...", "new_password": "..." }
    """
    nic = request.data.get('nic')
    current_password = request.data.get('current_password')
    new_password = request.data.get('new_password')
    if not nic or not current_password or not new_password:
        return Response({'error': 'All fields are required.'}, status=400)
    try:
        user_auth = UserAuth.objects.get(nic=nic)
        if not user_auth.check_password(current_password):
            return Response({'error': 'Current password is incorrect.'}, status=400)
        user_auth.set_password(new_password)
        user_auth.save()
        return Response({'message': 'Password changed successfully.'})
    except UserAuth.DoesNotExist:
        return Response({'error': 'User not found.'}, status=404)


