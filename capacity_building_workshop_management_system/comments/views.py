from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from workshops.models import Session
from .models import AdminComment

@api_view(['POST'])
def submit_admin_comment(request, session_id):
    """
    Create a new comment for a session.
    
    URL Parameters:
    - session_id: int (required)
    
    Request Body:
    - comment: str (required)
    
    Returns:
    - status: str (success/error)
    - message: str (description of the result)
    - comment: object (the created comment data)
    """
    comment_text = request.data.get('comment')

    if not comment_text:
        return Response(
            {"status": "error", "message": "Comment is required."}, 
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        session = Session.objects.get(id=session_id)
    except Session.DoesNotExist:
        return Response(
            {"status": "error", "message": "Invalid session ID."}, 
            status=status.HTTP_404_NOT_FOUND
        )

    # Check if comment already exists for this session
    if AdminComment.objects.filter(session=session).exists():
        return Response(
            {"status": "error", "message": "A comment already exists for this session. Use update endpoint instead."},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        admin_comment = AdminComment.objects.create(
            session=session, 
            comment=comment_text,
        )
        return Response({
            "status": "success",
            "message": "Comment created successfully.",
            "comment": {
                "id": admin_comment.id,
                "session_id": admin_comment.session_id,
                "comment": admin_comment.comment,
                "created_at": admin_comment.created_at,
                "updated_at": admin_comment.updated_at
            }
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response(
            {"status": "error", "message": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['PUT'])
def update_admin_comment(request, session_id):
    """
    Update an existing comment for a session.
    
    URL Parameters:
    - session_id: int (required)
    
    Request Body:
    - comment: str (required)
    
    Returns:
    - status: str (success/error)
    - message: str (description of the result)
    - comment: object (the updated comment data)
    """
    comment_text = request.data.get('comment')

    if not comment_text:
        return Response(
            {"status": "error", "message": "Comment is required."}, 
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        # Get the existing comment for this session
        admin_comment = AdminComment.objects.get(session_id=session_id)
        admin_comment.comment = comment_text
        admin_comment.save()
        
        return Response({
            "status": "success",
            "message": "Comment updated successfully.",
            "comment": {
                "id": admin_comment.id,
                "session_id": admin_comment.session_id,
                "comment": admin_comment.comment,
                "created_at": admin_comment.created_at,
                "updated_at": admin_comment.updated_at
            }
        }, status=status.HTTP_200_OK)
        
    except AdminComment.DoesNotExist:
        return Response(
            {"status": "error", "message": "No comment found for this session. Create one first."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {"status": "error", "message": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_admin_comments(request, session_id):
    """
    Get all comments for a session.
    
    URL Parameters:
    - session_id: int (required)
    
    Returns:
    - comments: list of {
        "id": int,
        "comment": str,
        "created_at": "datetime",
        "updated_at": "datetime"
      }
    """
    try:
        comments = AdminComment.objects.filter(session_id=session_id).order_by('-created_at')
        return Response([{
            "id": c.id,
            "comment": c.comment,
            "created_at": c.created_at,
            "updated_at": c.updated_at
        } for c in comments], status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {"status": "error", "message": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_workshop_admin_comments(request, workshop_id):
    """
    Get all admin comments for all sessions of a specific workshop.
    
    URL Parameters:
    - workshop_id: int (required)
    
    Returns:
    - comments: list of {
        "id": int,
        "session_id": int,
        "session_date": "datetime",
        "comment": str,
        "created_at": "datetime",
        "updated_at": "datetime"
      }
    """
    try:
        # Get all sessions for the workshop
        sessions = Session.objects.filter(workshop_id=workshop_id)
        
        # Get all comments for these sessions
        comments = AdminComment.objects.filter(session__in=sessions) \
            .select_related('session') \
            .order_by('-created_at')
            
        response_data = [{
            "id": c.id,
            "session_id": c.session.id,
            "session_date": c.session.date_time,
            "comment": c.comment,
            "created_at": c.created_at,
            "updated_at": c.updated_at
        } for c in comments]
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {"status": "error", "message": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

