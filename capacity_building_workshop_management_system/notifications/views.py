from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import NotificationTemplate, Notification
from registrations.models import Registration
from workshops.models import Session
from users.models import Participant
from .serializers import NotificationSerializer


@api_view(['GET'])
def list_notifications(request, participant_id):
    """
    Get all notifications for a specific participant.
    """
    try:
        notifications = Notification.objects.filter(participant_id=participant_id).order_by('-created_at')
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['POST'])
def mark_notification_read(request, notification_id):
    try:
        notification = Notification.objects.get(id=notification_id)
        notification.is_read = True
        notification.save()
        return Response({'message': 'Notification marked as read.'})
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found.'}, status=404)

@api_view(['POST'])
def send_notification(request):
    """
    Send notifications to participants.
    Accepts:
      - participant_ids: [1,2,3] (optional, send to these participants)
      - session_id: int (optional, send to all registered/attended participants of this session)
      - workshop_id: int (optional, send to all registered participants of all sessions in this workshop)
      - to_all: bool (optional, send to all participants)
      - attended_only: bool (optional, only for attended participants if session_id/workshop_id is given)
      - title: str (required)
      - message: str (required)
      - url: str (optional)
      - notification_type: str (optional)
    """
    title = request.data.get('title')
    message = request.data.get('message')
    url = request.data.get('url', '')
    notification_type = request.data.get('notification_type', 'general')
    participant_ids = request.data.get('participant_ids', [])
    session_id = request.data.get('session_id')
    workshop_id = request.data.get('workshop_id')
    to_all = request.data.get('to_all', False)
    attended_only = request.data.get('attended_only', False)

    # Create or get the template
    template, _ = NotificationTemplate.objects.get_or_create(
        title=title,
        message=message,
        url=url,
        notification_type=notification_type
    )

    participants = Participant.objects.none()
    if to_all:
        participants = Participant.objects.all()
    elif session_id:
        regs = Registration.objects.filter(session_id=session_id)
        if attended_only:
            regs = regs.filter(attendance=True)
        participants = Participant.objects.filter(id__in=regs.values_list('participant_id', flat=True))
    elif workshop_id:
        session_ids = Session.objects.filter(workshop_id=workshop_id).values_list('id', flat=True)
        regs = Registration.objects.filter(session_id__in=session_ids)
        if attended_only:
            regs = regs.filter(attendance=True)
        participants = Participant.objects.filter(id__in=regs.values_list('participant_id', flat=True))
    elif participant_ids:
        participants = Participant.objects.filter(id__in=participant_ids)
    else:
        return Response({'error': 'No target participants specified.'}, status=400)

    count = 0
    for participant in participants.distinct():
        Notification.objects.create(
            participant=participant,
            template=template
        )
        count += 1

    return Response({'message': f'Notifications sent to {count} participant(s).'}, status=200)

