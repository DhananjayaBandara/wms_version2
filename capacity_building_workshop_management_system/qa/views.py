from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Question
from users.models import Participant
from workshops.models import Session
from registrations.models import Registration
from .serializers import QuestionSerializer
from rest_framework.permissions import AllowAny
from rest_framework.decorators import permission_classes

@api_view(['GET'])
def list_session_questions(request, session_id):
    """
    List all questions for a specific session.
    Query params:
    - answered: true/false to filter by answered status
    """
    try:
        questions = Question.objects.filter(session_id=session_id)
        
        # Filter by answered status if provided
        answered = request.query_params.get('answered')
        if answered is not None:
            questions = questions.filter(is_answered=answered.lower() == 'true')
            
        serializer = QuestionSerializer(questions.order_by('-created_at'), many=True)
        return Response(serializer.data)
        
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
def participant_questions(request, participant_id):
    """
    Get all questions asked by a specific participant.
    """
    try:
        questions = Question.objects.filter(participant_id=participant_id)
        serializer = QuestionSerializer(questions.order_by('-created_at'), many=True)
        return Response(serializer.data)
        
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def trainer_questions(request, trainer_id):
    """
    Get all questions for sessions where the trainer is assigned.
    Query params:
    - answered: true/false to filter by answered status
    - session_id: filter by specific session
    """
    try:
        # Get all session IDs where this trainer is assigned
        session_ids = TrainerSession.objects.filter(
            trainer_id=trainer_id
        ).values_list('session_id', flat=True)
        
        questions = Question.objects.filter(session_id__in=session_ids)
        
        # Filter by answered status if provided
        answered = request.query_params.get('answered')
        if answered is not None:
            questions = questions.filter(is_answered=answered.lower() == 'true')
            
        # Filter by session if provided
        session_id = request.query_params.get('session_id')
        if session_id is not None:
            questions = questions.filter(session_id=session_id)
            
        serializer = QuestionSerializer(questions.order_by('-created_at'), many=True)
        return Response(serializer.data)
        
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def submit_question(request):
    """
    Submit a new question for a session.
    Expected payload:
    {
        "session": <session_id>,
        "participant": <participant_id>,
        "question_text": "..."
    }
    """
    try:
        data = request.data.copy()
        
        # Validate required fields
        required_fields = ['session', 'participant', 'question_text']
        for field in required_fields:
            if field not in data:
                return Response(
                    {"error": f"Missing required field: {field}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Check if participant exists
        try:
            participant = Participant.objects.get(id=data['participant'])
        except Participant.DoesNotExist:
            return Response(
                {"error": "Participant not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if session exists
        try:
            session = Session.objects.get(id=data['session'])
        except Session.DoesNotExist:
            return Response(
                {"error": "Session not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Create the question
        question = Question.objects.create(
            session=session,
            participant=participant,
            question_text=data['question_text'],
            is_answered=False
        )
        
        # Return the created question
        serializer = QuestionSerializer(question)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['POST', 'PATCH'])
@permission_classes([AllowAny])
def mark_question_answered(request, question_id):
    """
    Mark a question as answered.
    
    Methods: POST, PATCH
    URL: /api/questions/{question_id}/mark_answered/
    
    Request Body (optional):
    {
        "is_answered": true/false  # Defaults to true if not provided
    }
    
    Returns:
    {
        "message": "Question status updated",
        "question_id": 123,
        "is_answered": true/false
    }
    """
    try:
        # Get the question
        question = Question.objects.get(id=question_id)
        
        # Determine the new answered status
        is_answered = request.data.get('is_answered', True)
        if not isinstance(is_answered, bool):
            is_answered = str(is_answered).lower() == 'true'
        
        # Update the question status
        question.is_answered = is_answered
        question.save(update_fields=['is_answered'])
        
        return Response(
            {
                "message": "Question status updated",
                "question_id": question.id,
                "is_answered": question.is_answered
            },
            status=status.HTTP_200_OK
        )
    except Question.DoesNotExist:
        return Response(
            {"error": "Question not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )