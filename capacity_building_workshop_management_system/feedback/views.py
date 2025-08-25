
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import FeedbackQuestion, FeedbackResponse
from .serializers import FeedbackQuestionSerializer, FeedbackResponseSerializer
from registrations.models import Registration
from notifications.models import NotificationTemplate, Notification
from workshops.models import Session
from users.models import Participant

@api_view(['POST'])
def create_feedback_question(request):
    serializer = FeedbackQuestionSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        question = serializer.save()
        # Create or get the notification template
        template, _ = NotificationTemplate.objects.get_or_create(
            title="New Feedback Question",
            message=f"New feedback questions have been added for your session '{question.session}'.",
            url=f"/sessions/{question.session.id}/feedback/",
            notification_type="feedback"
        )
        # Notify attended participants
        attended_regs = Registration.objects.filter(session=question.session, attendance=True)
        for reg in attended_regs:
            Notification.objects.create(
                participant=reg.participant,
                template=template
            )
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def list_feedback_questions(request, session_id):
    questions = FeedbackQuestion.objects.filter(session_id=session_id)
    serializer = FeedbackQuestionSerializer(questions, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def submit_feedback_response(request):
    participant_id = request.data.get('participant')
    question_id = request.data.get('question')
    response_value = request.data.get('response')

    # Prevent duplicate feedback for the same participant/question/response
    if FeedbackResponse.objects.filter(
        participant_id=participant_id,
        question_id=question_id,
        response=response_value
    ).exists():
        return Response(
            {"error": "You have already submitted this response for this question."},
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = FeedbackResponseSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def list_feedback_responses(request, session_id):
    # Fix: filter by question__session_id instead of session_id
    responses = FeedbackResponse.objects.filter(question__session_id=session_id)
    serializer = FeedbackResponseSerializer(responses, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def feedback_analysis(request, session_id):
    analysis_result = analyze_feedback_for_session(session_id)
    return Response(analysis_result)


def session_feedback_analysis(request, session_id):
    analysis_result = analyze_session_feedback(session_id)
    return JsonResponse(analysis_result)
