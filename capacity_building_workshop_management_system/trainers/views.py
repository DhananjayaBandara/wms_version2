from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import TrainerCredential
from .serializers import TrainerCredentialSerializer
from .models import Trainer
from .serializers import TrainerSerializer
from rest_framework import status
from django.shortcuts import get_object_or_404
from assignments.models import TrainerSession

@api_view(['GET'])
def list_trainers(request):
    """
    List all trainers.
    """
    trainers = Trainer.objects.all()
    serializer = TrainerSerializer(trainers, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_trainer(request):
    """
    Create a new trainer.
    Expects: { "name": "...", "designation": "...", "email": "...", "contact_number": "...", "expertise": "..." }
    """
    serializer = TrainerSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_trainer(request, trainer_id):
    """
    Update a trainer.
    Expects: { "name": "...", "designation": "...", "email": "...", "contact_number": "...", "expertise": "..." }
    """
    trainer = get_object_or_404(Trainer, id=trainer_id)
    serializer = TrainerSerializer(trainer, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_trainer(request, trainer_id):
    """
    Delete a trainer.
    """
    trainer = get_object_or_404(Trainer, id=trainer_id)
    trainer.delete()
    return Response({"message": "Trainer deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_trainer_details(request, trainer_id):
    """
    Get trainer details.
    """
    try:
        trainer = Trainer.objects.get(id=trainer_id)
        sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session__workshop')
        session_data = [
            {
                "session_id": session.session.id,
                "session_title": str(session.session),
                "workshop_title": session.session.workshop.title,
                "date": session.session.date,
                "time": session.session.time,
                "location": session.session.location,
            }
            for session in sessions
        ]
        trainer_data = {
            "trainer_id": trainer.id,
            "name": trainer.name,
            "designation": trainer.designation,
            "email": trainer.email,
            "contact_number": trainer.contact_number,
            "expertise": trainer.expertise,
            "sessions": session_data,
        }
        return Response(trainer_data, status=status.HTTP_200_OK)
    except Trainer.DoesNotExist:
        return Response({"error": "Trainer not found"}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
def trainer_login(request):
    """
    Login for a trainer.
    Expects: { "username": "...", "password": "..." }
    """
    username = request.data.get('username')
    password = request.data.get('password')
    if not username or not password:
        return Response({'error': 'Username and password are required.'}, status=400)
    try:
        credential = TrainerCredential.objects.get(username=username)
        if credential.check_password(password):
            return Response({'trainer_id': credential.trainer.id, 'message': 'Login successful.'})
        else:
            return Response({'error': 'Invalid username or password.'}, status=401)
    except TrainerCredential.DoesNotExist:
        return Response({'error': 'Invalid username or password.'}, status=401)

@api_view(['POST'])
def create_trainer_credential(request, trainer_id):
    """
    Create username and password for a given trainer.
    Expects: { "username": "...", "password": "..." }
    """

    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': 'Username and password are required.'}, status=400)

    # Check if credential already exists for this trainer
    if TrainerCredential.objects.filter(trainer_id=trainer_id).exists():
        return Response({'error': 'Credential already exists for this trainer.'}, status=400)
    # Check if username is already taken
    if TrainerCredential.objects.filter(username=username).exists():
        return Response({'error': 'Username already taken.'}, status=400)

    data = {
        'trainer_id': trainer_id,
        'username': username,
        'password': password
    }
    serializer = TrainerCredentialSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response({'message': 'Trainer credential created successfully.'}, status=201)
    return Response(serializer.errors, status=400)

@api_view(['PUT'])
def update_trainer_credential(request, trainer_id):
    """
    Update username and/or password for a trainer.
    Expects: { "username": "...", "password": "..." }
    """
    try:
        credential = TrainerCredential.objects.get(trainer_id=trainer_id)
    except TrainerCredential.DoesNotExist:
        return Response({'error': 'Credential not found.'}, status=404)

    username = request.data.get('username')
    password = request.data.get('password')

    # Check for username uniqueness if changed
    if username and username != credential.username:
        if TrainerCredential.objects.filter(username=username).exists():
            return Response({'error': 'Username already taken.'}, status=400)
        credential.username = username

    if password:
        from django.contrib.auth.hashers import make_password
        credential.password = make_password(password)

    credential.save()
    return Response({'message': 'Credential updated successfully.'})


