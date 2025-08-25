from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from trainers.models import Trainer
from workshops.models import Session
from assignments.models import TrainerSession
from assignments.serializers import TrainerSessionSerializer
from rest_framework import status
from django.shortcuts import get_object_or_404

@api_view(['POST'])
def assign_trainer_to_session(request):
    """
    Assign trainers to a session.
    Expects: { "session_id": "...", "trainer_ids": ["...", ...] }
    """
    session_id = request.data.get('session_id')
    trainer_ids = request.data.get('trainer_ids', [])

    if not session_id or not isinstance(trainer_ids, list):
        return Response(
            {"error": "Invalid data. 'session_id' and 'trainer_ids' are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        session = get_object_or_404(Session, id=session_id)
        assigned_trainers = []

        for trainer_id in trainer_ids:
            trainer = get_object_or_404(Trainer, id=trainer_id)
            trainer_session, created = TrainerSession.objects.get_or_create(
                session=session, trainer=trainer
            )
            if created:
                assigned_trainers.append(trainer.id)

        return Response(
            {
                "message": "Trainers assigned successfully.",
                "assigned_trainers": assigned_trainers,
            },
            status=status.HTTP_201_CREATED,
        )
    except Exception as e:
        return Response(
            {"error": f"An error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

@api_view(['DELETE'])
def remove_trainer_from_session(request):
    """
    Remove a trainer from a session.
    Expects: { "session_id": "...", "trainer_id": "..." }
    """
    session_id = request.data.get('session_id')
    trainer_id = request.data.get('trainer_id')

    if not session_id or not trainer_id:
        return Response(
            {"error": "Invalid data. 'session_id' and 'trainer_id' are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        trainer_session = get_object_or_404(
            TrainerSession, session_id=session_id, trainer_id=trainer_id
        )
        trainer_session.delete()
        return Response(
            {"message": "Trainer removed successfully."},
            status=status.HTTP_200_OK,
        )
    except Exception as e:
        return Response(
            {"error": f"An error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

