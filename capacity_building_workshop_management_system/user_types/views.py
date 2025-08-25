from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import ParticipantType
from .serializers import ParticipantTypeSerializer
from django.shortcuts import get_object_or_404

@api_view(['GET'])
def list_participant_types(request):
    """
    List all participant types.
    """
    types = ParticipantType.objects.all()
    serializer = ParticipantTypeSerializer(types, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_participant_type(request):
    """
    Create a new participant type.
    Expects: { "name": "...", "description": "...", "properties": {...} }
    """
    serializer = ParticipantTypeSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_participant_type(request, type_id):
    """
    Update a participant type.
    Expects: { "name": "...", "description": "...", "properties": {...} }
    """
    participant_type = get_object_or_404(ParticipantType, id=type_id)
    serializer = ParticipantTypeSerializer(participant_type, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_participant_type(request, type_id):
    """
    Delete a participant type.
    """
    participant_type = get_object_or_404(ParticipantType, id=type_id)
    participant_type.delete()
    return Response({"message": "Participant type deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_required_fields_for_participant_type(request, type_id):
    """
    Get required fields for a participant type.
    """
    try:
        participant_type = ParticipantType.objects.get(id=type_id)
        return Response({
            "type_id": participant_type.id,
            "type_name": participant_type.name,
            "required_fields": participant_type.properties
        })
    except ParticipantType.DoesNotExist:
        return Response(
            {"error": "Participant type not found."},
            status=status.HTTP_404_NOT_FOUND
        )

