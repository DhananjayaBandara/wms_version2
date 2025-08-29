from rest_framework.decorators import api_view
from rest_framework.response import Response
from workshops.models import Session, Workshop
from registrations.models import Registration
from assignments.models import TrainerSession
from feedback.models import FeedbackResponse, FeedbackQuestion
from trainers.models import Trainer
from users.models import Participant
from user_types.models import ParticipantType
from .serializers import TrainerDashboardSerializer
from collections import Counter
from datetime import datetime, timedelta


@api_view(['GET'])
def trainer_dashboard(request, trainer_id=None):
    if (trainer_id):
        try:
            trainer = Trainer.objects.get(id=trainer_id)
        except Trainer.DoesNotExist:
            return Response({"error": "Trainer not found"}, status=404)

        sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session')

        dashboard_data = []

        for ts in sessions:
            session = ts.session
            registrations = Registration.objects.filter(session=session)
            total = registrations.count()
            attended = registrations.filter(attendance=True).count()

            # Calculate average rating from feedback
            rating_responses = FeedbackResponse.objects.filter(
                question__session=session,
                question__response_type='scale'
            ).values_list('response', flat=True)

            try:
                ratings = [float(r) for r in rating_responses if r is not None]
                avg_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
            except:
                avg_rating = None

            dashboard_data.append({
                "session_id": session.id,
                "session_title": str(session),
                "date": session.date,
                "time": session.time,
                "workshop_title": session.workshop.title,
                "location": session.location,
                "total_participants": total,
                "attendance_count": attended,
                "average_rating": avg_rating
            })

        serializer = TrainerDashboardSerializer(dashboard_data, many=True)
        return Response(serializer.data)

    # Admin dashboard for all trainers
    trainers = Trainer.objects.all()
    trainer_data = []

    for trainer in trainers:
        sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session')
        session_count = sessions.count()
        trainer_data.append({
            "trainer_id": trainer.id,
            "trainer_name": trainer.name,
            "designation": trainer.designation,
            "email": trainer.email,
            "contact_number": trainer.contact_number,
            "expertise": trainer.expertise,
            "session_count": session_count
        })

    return Response(trainer_data)

@api_view(['GET'])
def admin_dashboard_counts(request):
    counts = {
        "workshops": Workshop.objects.count(),
        "sessions": Session.objects.count(),
        "participants": Participant.objects.count(),
        "participant_types": ParticipantType.objects.count(),
        "trainers": Trainer.objects.count(),
    }
    return Response(counts)

@api_view(['GET'])
def session_statistics_dashboard(request, session_id):
    stats = compute_and_update_session_statistics(session_id)
    data = {
        "session_id": stats.session.id,
        "registered_count": stats.registered_count,
        "attended_count": stats.attended_count,
        "attendance_percentage": stats.attendance_percentage,
        "average_rating": stats.average_rating,
        "impact_summary": stats.impact_summary,
        "improvement_suggestions": stats.improvement_suggestions,
    }
    return Response(data)

@api_view(['GET'])
def analytics_sessions(request):
    total_sessions = Session.objects.count()
    # Average attendance: mean of attended participants per session
    sessions = Session.objects.all()
    total_attendance = 0
    for session in sessions:
        attended = Registration.objects.filter(session=session, attendance=True).count()
        total_attendance += attended
    average_attendance = round(total_attendance / total_sessions, 2) if total_sessions > 0 else 0
    return Response({
        "total_sessions": total_sessions,
        "average_attendance": average_attendance,
    })

@api_view(['GET'])
def analytics_workshops(request):
    total_workshops = Workshop.objects.count()
    # Average rating: mean of all feedback ratings for all workshops' sessions
    sessions = Session.objects.all()
    ratings = []
    for session in sessions:
        responses = FeedbackResponse.objects.filter(
            question__session=session,
            question__response_type__in=['scale', 'rating']
        ).values_list('response', flat=True)
        for r in responses:
            try:
                ratings.append(float(r))
            except Exception:
                continue
    average_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
    return Response({
        "total_workshops": total_workshops,
        "average_rating": average_rating,
    })

@api_view(['GET'])
def analytics_trainers(request):
    total_trainers = Trainer.objects.count()
    # Top rated trainer: trainer with highest average rating across their sessions
    trainers = Trainer.objects.all()
    top_trainer = None
    top_rating = None
    for trainer in trainers:
        trainer_sessions = TrainerSession.objects.filter(trainer=trainer)
        ratings = []
        for ts in trainer_sessions:
            responses = FeedbackResponse.objects.filter(
                question__session=ts.session,
                question__response_type__in=['scale', 'rating']
            ).values_list('response', flat=True)
            for r in responses:
                try:
                    ratings.append(float(r))
                except Exception:
                    continue
        avg = sum(ratings) / len(ratings) if ratings else None
        if avg is not None and (top_rating is None or avg > top_rating):
            top_rating = avg
            top_trainer = trainer.name
    return Response({
        "total_trainers": total_trainers,
        "top_trainer": top_trainer or "N/A",
    })

@api_view(['GET'])
def analytics_participants(request):
    total_participants = Participant.objects.count()
    # Average completion rate: percentage of attended sessions over registered sessions
    total_registrations = Registration.objects.count()
    total_attended = Registration.objects.filter(attendance=True).count()
    average_completion_rate = round((total_attended / total_registrations) * 100, 2) if total_registrations > 0 else 0
    return Response({
        "total_participants": total_participants,
        "average_completion_rate": average_completion_rate,
    })


@api_view(['GET'])
def analytics_sessions_overview(request):
    """
    Returns:
    - total_sessions
    - total_registered
    - total_attended
    - average_attendance_rate
    - feedback_count (number of distinct participants who submitted feedback)
    - average_feedback_rating
    - common_feedback_keywords
    - session_titles
    - registrations_per_session
    - attendance_per_session
    """
    sessions = Session.objects.all()
    total_sessions = sessions.count()
    total_registered = 0
    total_attended = 0
    session_titles = []
    registrations_per_session = []
    attendance_per_session = []

    feedback_count = 0
    feedback_ratings = []
    feedback_texts = []

    # --- Count distinct participants who submitted feedback ---
    feedback_participant_ids = set(
        FeedbackResponse.objects.values_list('participant_id', flat=True).distinct()
    )
    feedback_count = len(feedback_participant_ids)

    for session in sessions:
        regs = Registration.objects.filter(session=session)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        total_registered += reg_count
        total_attended += att_count
        session_titles.append(str(session))
        registrations_per_session.append(reg_count)
        attendance_per_session.append(att_count)

        # Feedback
        responses = FeedbackResponse.objects.filter(question__session=session)
        # Ratings
        for resp in responses.filter(question__response_type__in=['scale', 'rating']):
            try:
                feedback_ratings.append(float(resp.response))
            except Exception:
                continue
        # Suggestions/comments
        for resp in responses.filter(question__response_type='text'):
            if resp.response:
                feedback_texts.append(resp.response)

    average_attendance_rate = round((total_attended / total_registered) * 100, 2) if total_registered > 0 else 0
    average_feedback_rating = round(sum(feedback_ratings) / len(feedback_ratings), 2) if feedback_ratings else None

    # Simple keyword extraction (top 5 words, ignoring short/common words)
    words = []
    for text in feedback_texts:
        words += [w.lower() for w in text.split() if len(w) > 3]
    common_feedback_keywords = [w for w, _ in Counter(words).most_common(5)]

    return Response({
        "total_sessions": total_sessions,
        "total_registered": total_registered,
        "total_attended": total_attended,
        "average_attendance_rate": average_attendance_rate,
        "feedback_count": feedback_count,
        "average_feedback_rating": average_feedback_rating,
        "common_feedback_keywords": common_feedback_keywords,
        "session_titles": session_titles,
        "registrations_per_session": registrations_per_session,
        "attendance_per_session": attendance_per_session,
    })

@api_view(['GET'])
def analytics_sessions_list(request):
    """
    Returns a list of sessions with:
    - id, title, workshop, date, time, registered_count, attended_count, avg_feedback_rating
    """
    sessions = Session.objects.select_related('workshop').all().order_by('-date')
    data = []
    for session in sessions:
        regs = Registration.objects.filter(session=session)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        # Feedback
        responses = FeedbackResponse.objects.filter(question__session=session, question__response_type__in=['scale', 'rating'])
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
            except Exception:
                continue
        avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        data.append({
            "id": session.id,
            "title": str(session),
            "location": session.location,
            "workshop": session.workshop.title if session.workshop else "",
            "date": session.date,
            "time": session.time,
            "registered_count": reg_count,
            "attended_count": att_count,
            "avg_feedback_rating": avg_feedback_rating,
        })
    return Response(data)

@api_view(['GET'])
def analytics_session_detail(request, session_id):
    """
    Returns:
    - session info
    - registered/attended counts
    - participants list (name, email, attended)
    - feedback rating distribution
    - feedback summary (top suggestions/problems, recommendations)
    """
    session = Session.objects.get(id=session_id)
    regs = Registration.objects.filter(session=session).select_related('participant')
    reg_count = regs.count()
    att_count = regs.filter(attendance=True).count()
    participants = []
    for reg in regs:
        participants.append({
            "name": reg.participant.name,
            "email": reg.participant.email,
            "attended": reg.attendance,
        })

    # Feedback ratings distribution
    responses = FeedbackResponse.objects.filter(question__session=session, question__response_type__in=['scale', 'rating'])
    rating_counts = Counter()
    for resp in responses:
        try:
            rating = int(float(resp.response))
            rating_counts[rating] += 1
        except Exception:
            continue

    # Feedback suggestions/comments
    text_responses = FeedbackResponse.objects.filter(question__session=session, question__response_type='text')
    suggestions = [resp.response for resp in text_responses if resp.response]
    # Top 3 suggestions/problems (by frequency)
    words = []
    for text in suggestions:
        words += [w.lower() for w in text.split() if len(w) > 3]
    top_keywords = [w for w, _ in Counter(words).most_common(5)]
    
    # --- Session funnel: number of distinct participants who submitted feedback for a selected session ---
    # Get all feedback questions for the sessions
    question_ids = list(FeedbackQuestion.objects.filter(session=session).values_list('id', flat=True))
    feedback_participant_ids = (
        FeedbackResponse.objects
        .filter(question_id__in=question_ids)
        .values_list('participant_id', flat=True)
        .distinct()
    )
    feedback_participants_count = len(set(feedback_participant_ids))

    return Response({
        "session_id": session.id,
        "title": str(session),
        "workshop": session.workshop.title if session.workshop else "",
        "date": session.date,
        "time": session.time,
        "location": session.location,
        "registered_count": reg_count,
        "attended_count": att_count,
        "participants": participants,
        "feedback_rating_distribution": rating_counts,
        "feedback_suggestions": suggestions[:5],
        "top_keywords": top_keywords,
        "feedback_participants": feedback_participants_count,
    })

from collections import Counter

@api_view(['GET'])
def analytics_workshops_overview(request):
    """
    Returns:
    - total_workshops
    - total_sessions
    - total_registered
    - total_attended
    - average_attendance_rate
    - average_feedback_rating
    - workshop_titles
    - registrations_per_workshop
    - attendance_per_workshop
    """
    workshops = Workshop.objects.all()
    total_workshops = workshops.count()
    total_sessions = 0
    total_registered = 0
    total_attended = 0
    workshop_titles = []
    registrations_per_workshop = []
    attendance_per_workshop = []
    feedback_ratings = []
    
    feedback_participant_ids = set(
    FeedbackResponse.objects.filter(question__session__workshop__in=workshops)
    .values_list('participant_id', flat=True)
    .distinct()
    )
    feedback_participants = len(feedback_participant_ids)


    for workshop in workshops:
        sessions = Session.objects.filter(workshop=workshop)
        session_ids = sessions.values_list('id', flat=True)
        session_count = sessions.count()
        total_sessions += session_count

        regs = Registration.objects.filter(session__in=session_ids)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        total_registered += reg_count
        total_attended += att_count

        workshop_titles.append(workshop.title)
        registrations_per_workshop.append(reg_count)
        attendance_per_workshop.append(att_count)

        # Feedback ratings for all sessions under this workshop
        responses = FeedbackResponse.objects.filter(question__session__in=session_ids, question__response_type__in=['scale', 'rating'])
        for resp in responses:
            try:
                feedback_ratings.append(float(resp.response))
            except Exception:
                continue

    average_attendance_rate = round((total_attended / total_registered) * 100, 2) if total_registered > 0 else 0
    average_feedback_rating = round(sum(feedback_ratings) / len(feedback_ratings), 2) if feedback_ratings else None
    

    return Response({
        "total_workshops": total_workshops,
        "total_sessions": total_sessions,
        "total_registered": total_registered,
        "total_attended": total_attended,
        "average_attendance_rate": average_attendance_rate,
        "average_feedback_rating": average_feedback_rating,
        "workshop_titles": workshop_titles,
        "registrations_per_workshop": registrations_per_workshop,
        "attendance_per_workshop": attendance_per_workshop,
        "feedback_participants": feedback_participants,
    })

@api_view(['GET'])
def analytics_workshops_list(request):
    """
    Returns a list of workshops with:
    - id, title, total_sessions, total_registered, total_attended, avg_feedback_rating
    """
    workshops = Workshop.objects.all()
    data = []
    for workshop in workshops:
        sessions = Session.objects.filter(workshop=workshop)
        session_ids = sessions.values_list('id', flat=True)
        session_count = sessions.count()
        regs = Registration.objects.filter(session__in=session_ids)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        # Feedback
        responses = FeedbackResponse.objects.filter(question__session__in=session_ids, question__response_type__in=['scale', 'rating'])
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
            except Exception:
                continue
        avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        data.append({
            "id": workshop.id,
            "title": workshop.title,
            "total_sessions": session_count,
            "total_registered": reg_count,
            "total_attended": att_count,
            "avg_feedback_rating": avg_feedback_rating,
        })
    return Response(data)

@api_view(['GET'])
def analytics_workshop_detail(request, workshop_id):
    """
    Returns:
    - workshop info
    - registration/attendance totals (across all sessions of this workshop)
    - feedback summary (ratings, suggestions)
    - trend data over sessions
    - feedback_participants: number of distinct participants who submitted feedback for this workshop
    """
    from collections import Counter

    workshop = Workshop.objects.get(id=workshop_id)
    sessions = Session.objects.filter(workshop=workshop).order_by('date')
    session_ids = list(sessions.values_list('id', flat=True))
    session_titles = [str(s) for s in sessions]
    session_dates = [s.date for s in sessions]

    # --- Calculate total registered and attended ---
    regs = Registration.objects.filter(session_id__in=session_ids)
    reg_count = regs.count()
    att_count = regs.filter(attendance=True).count()

    # Feedback ratings
    responses = FeedbackResponse.objects.filter(question__session_id__in=session_ids, question__response_type__in=['scale', 'rating'])
    ratings = []
    for resp in responses:
        try:
            ratings.append(float(resp.response))
        except Exception:
            continue
    avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None

    # Suggestions/comments
    text_responses = FeedbackResponse.objects.filter(question__session_id__in=session_ids, question__response_type='text')
    suggestions = [resp.response for resp in text_responses if resp.response]
    words = []
    for text in suggestions:
        words += [w.lower() for w in text.split() if len(w) > 3]
    top_keywords = [w for w, _ in Counter(words).most_common(5)]

    # Trend data: for each session, get reg/att/avg_rating
    trend = []
    for s in sessions:
        s_regs = regs.filter(session=s)
        s_reg_count = s_regs.count()
        s_att_count = s_regs.filter(attendance=True).count()
        s_responses = FeedbackResponse.objects.filter(question__session=s, question__response_type__in=['scale', 'rating'])
        s_ratings = []
        for resp in s_responses:
            try:
                s_ratings.append(float(resp.response))
            except Exception:
                continue
        avg_rating = round(sum(s_ratings) / len(s_ratings), 2) if s_ratings else None
        trend.append({
            "session_id": s.id,
            "title": str(s),
            "date": s.date,
            "time": s.time,
            "registered": s_reg_count,
            "attended": s_att_count,
            "avg_rating": avg_rating,
        })

    # --- Workshop funnel: number of distinct participants who submitted feedback for this workshop ---
    question_ids = list(FeedbackQuestion.objects.filter(session_id__in=session_ids).values_list('id', flat=True))
    feedback_participant_ids = (
        FeedbackResponse.objects
        .filter(question_id__in=question_ids)
        .values_list('participant_id', flat=True)
        .distinct()
    )
    feedback_participants_count = len(set(feedback_participant_ids))

    # List of all participants registered for any session in this workshop
    participants = regs.select_related('participant')
    participants_list = [
        {
            "name": reg.participant.name,
            "email": reg.participant.email,
        }
        for reg in participants
    ]

    return Response({
        "workshop_id": workshop.id,
        "title": workshop.title,
        "description": getattr(workshop, "description", ""),
        "total_sessions": sessions.count(),
        "total_registered": reg_count,
        "total_attended": att_count,  
        "avg_feedback_rating": avg_feedback_rating,
        "feedback_suggestions": suggestions[:5],
        "top_keywords": top_keywords,
        "trend": trend,
        "session_titles": session_titles,
        "session_dates": session_dates,
        "feedback_participants": feedback_participants_count,
        "participants": participants_list,
    })


@api_view(['GET'])
def analytics_trainers(request):
    """
    Returns:
    - total_trainers
    - top_trainer
    - trainers: list of {id, name, email, session_count, avg_feedback_rating}
    """
    trainers = Trainer.objects.all()
    trainers_list = []
    top_trainer = None
    top_rating = None
    for trainer in trainers:
        trainer_sessions = TrainerSession.objects.filter(trainer=trainer)
        session_count = trainer_sessions.count()
        ratings = []
        total_participants = 0
        for ts in trainer_sessions:
            regs = Registration.objects.filter(session=ts.session)
            total_participants += regs.count()
            responses = FeedbackResponse.objects.filter(
                question__session=ts.session,
                question__response_type__in=['scale', 'rating']
            ).values_list('response', flat=True)
            for r in responses:
                try:
                    ratings.append(float(r))
                except Exception:
                    continue
        avg = round(sum(ratings) / len(ratings), 2) if ratings else None
        if avg is not None and (top_rating is None or avg > top_rating):
            top_rating = avg
            top_trainer = trainer.name
        trainers_list.append({
            "id": trainer.id,
            "name": trainer.name,
            "email": trainer.email,
            "session_count": session_count,
            "avg_feedback_rating": avg,
            "total_participants": total_participants,
        })
    return Response({
        "total_trainers": trainers.count(),
        "top_trainer": top_trainer or "N/A",
        "trainers": trainers_list,
    })

@api_view(['GET'])
def analytics_trainer_detail(request, trainer_id):
    """
    Returns:
    - name, email, session_count, total_participants, avg_feedback_rating
    - ratings_trend: [{session_title, date_time, avg_rating}]
    - feedback_themes: top keywords from feedback
    """
    trainer = Trainer.objects.get(id=trainer_id)
    trainer_sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session')
    session_count = trainer_sessions.count()
    ratings_trend = []
    all_ratings = []
    total_participants = 0
    feedback_texts = []
    for ts in trainer_sessions:
        session = ts.session
        regs = Registration.objects.filter(session=session)
        total_participants += regs.count()
        responses = FeedbackResponse.objects.filter(
            question__session=session,
            question__response_type__in=['scale', 'rating']
        )
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
                all_ratings.append(float(resp.response))
            except Exception:
                continue
        avg_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        ratings_trend.append({
            "session_title": str(session),
            "date": session.date,
            "time": session.time,
            "avg_rating": avg_rating,
        })
        # Text feedback for this session
        text_responses = FeedbackResponse.objects.filter(
            question__session=session,
            question__response_type='text'
        )
        for resp in text_responses:
            if resp.response:
                feedback_texts.append(resp.response)
    avg_feedback_rating = round(sum(all_ratings) / len(all_ratings), 2) if all_ratings else None
    # Simple keyword extraction (top 5 words, ignoring short/common words)
    words = []
    for text in feedback_texts:
        words += [w.lower() for w in text.split() if len(w) > 3]
    feedback_themes = [w for w, _ in Counter(words).most_common(5)]
    return Response({
        "id": trainer.id,
        "name": trainer.name,
        "email": trainer.email,
        "session_count": session_count,
        "total_participants": total_participants,
        "avg_feedback_rating": avg_feedback_rating,
        "ratings_trend": ratings_trend,
        "feedback_themes": feedback_themes,
    })

from collections import Counter
from django.db.models import Q

@api_view(['GET'])
def analytics_participants_overview(request):
    """
    Returns:
    - total_participants
    - district_histogram: {district: count}
    - gender_distribution: {gender: count}
    - type_distribution: {type: count}
    - attendance_percentage
    - feedback_response_rate
    - top_10_participants: list of top 10 participants by attended sessions, including registered session count
    - filters: district, gender, participant_type, date range
    """
    # Filters
    district = request.GET.get('district')
    gender = request.GET.get('gender')
    participant_type = request.GET.get('participant_type')
    date_from = request.GET.get('date_from')
    date_to = request.GET.get('date_to')
    workshop_id = request.GET.get('workshop_id')
    session_id = request.GET.get('session_id')

    participants = Participant.objects.all()
    regs = Registration.objects.all()
    feedbacks = FeedbackResponse.objects.all()

    # Apply filters
    if district:
        participants = participants.filter(district=district)
    if gender:
        participants = participants.filter(gender=gender)
    if participant_type:
        participants = participants.filter(participant_type__name=participant_type)
    if date_from:
        regs = regs.filter(registered_on__gte=date_from)
    if date_to:
        regs = regs.filter(registered_on__lte=date_to)
    if workshop_id:
        regs = regs.filter(session__workshop_id=workshop_id)
    if session_id:
        regs = regs.filter(session_id=session_id)

    participant_ids = participants.values_list('id', flat=True)
    regs = regs.filter(participant_id__in=participant_ids)
    attended_regs = regs.filter(attendance=True)

    # Histogram: District
    district_hist = Counter(participants.values_list('district', flat=True))
    # Pie: Gender
    gender_dist = Counter(participants.values_list('gender', flat=True))
    # Pie: Participant Type
    type_dist = Counter(
        participants.values_list('participant_type__name', flat=True)
    )

    total_participants = participants.count()
    total_registered = regs.count()
    total_attended = attended_regs.count()

    attendance_percentage = round((total_attended / total_registered) * 100, 2) if total_registered > 0 else 0

    # Feedback response rate: attendees who submitted at least one feedback
    attendee_ids = attended_regs.values_list('participant_id', flat=True)
    feedback_participant_ids = feedbacks.filter(participant_id__in=attendee_ids).values_list('participant_id', flat=True).distinct()
    feedback_response_rate = round((len(feedback_participant_ids) / len(attendee_ids)) * 100, 2) if attendee_ids else 0

    # --- Top 10 participants by attended sessions ---
    attended_counts = Counter(attended_regs.values_list('participant_id', flat=True))
    top_10_ids = [pid for pid, _ in attended_counts.most_common(10)]
    top_10_participants = []
    if top_10_ids:
        top_participants_qs = Participant.objects.filter(id__in=top_10_ids)
        # Map id to participant for fast lookup
        id_to_participant = {p.id: p for p in top_participants_qs}
        for pid in top_10_ids:
            p = id_to_participant.get(pid)
            if p:
                # Count number of sessions registered by this participant
                registered_sessions_count = Registration.objects.filter(participant_id=pid).count()
                top_10_participants.append({
                    "id": p.id,
                    "name": p.name,
                    "email": p.email,                 
                    "attended_sessions": attended_counts[pid],
                    "registered_sessions": registered_sessions_count,
                })

    districts = list(Participant.objects.values_list('district', flat=True).distinct())
    genders = list(Participant.objects.values_list('gender', flat=True).distinct())
    participant_types = list(ParticipantType.objects.values_list('name', flat=True).distinct())

    return Response({
        "total_participants": total_participants,
        "district_histogram": dict(district_hist),
        "gender_distribution": dict(gender_dist),
        "type_distribution": dict(type_dist),
        "attendance_percentage": attendance_percentage,
        "feedback_response_rate": feedback_response_rate,
        "top_10_participants": top_10_participants,
        "available_filters": {
            "districts": districts,
            "genders": genders,
            "participant_types": participant_types,
        }
    })

@api_view(['GET'])
def sessions_report_overview(request):
    """
    Returns an overview report of workshop sessions for a given period.
    Query params:
      - period: 'daily', 'weekly', 'monthly', 'annual', or 'custom'
      - date_from: (YYYY-MM-DD) for custom
      - date_to: (YYYY-MM-DD) for custom
    """
    period = request.GET.get('period', 'custom')
    date_from = request.GET.get('date_from')
    date_to = request.GET.get('date_to')

    now = datetime.now()  

    if period == 'daily':
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = now.replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == 'weekly':
        start = now - timedelta(days=now.weekday())
        start = start.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=6, hours=23, minutes=59, seconds=59, microseconds=999999)
    elif period == 'monthly':
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        if now.month == 12:
            end = start.replace(year=now.year+1, month=1) - timedelta(microseconds=1)
        else:
            end = start.replace(month=now.month+1) - timedelta(microseconds=1)
    elif period == 'annual':
        start = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end = now.replace(month=12, day=31, hour=23, minute=59, second=59, microsecond=999999)
    else:  # custom
        if date_from:
            if isinstance(date_from, str):
                from django.utils.dateparse import parse_date as django_parse_date
                date_from = django_parse_date(date_from)
            start = datetime.combine(date_from, datetime.min.time())
        else:
            start = Session.objects.earliest('date').date if Session.objects.exists() else now
        if date_to:
            if isinstance(date_to, str):
                from django.utils.dateparse import parse_date as django_parse_date
                date_to = django_parse_date(date_to)
            end = datetime.combine(date_to, datetime.max.time())
        else:
            end = now

    sessions = Session.objects.filter(date__range=(start, end))
    session_ids = list(sessions.values_list('id', flat=True))
    total_sessions = sessions.count()

    regs = Registration.objects.filter(session_id__in=session_ids)
    reg_count = regs.count()
    att_count = regs.filter(attendance=True).count()

    # Participant IDs
    registered_participant_ids = list(regs.values_list('participant_id', flat=True).distinct())
    attended_participant_ids = list(regs.filter(attendance=True).values_list('participant_id', flat=True).distinct())

    # Feedback
    feedback_responses = FeedbackResponse.objects.filter(question__session_id__in=session_ids)
    feedback_participant_ids = list(feedback_responses.values_list('participant_id', flat=True).distinct())
    feedback_count = len(set(feedback_participant_ids))

    # Feedback summary (ratings)
    ratings = []
    for resp in feedback_responses:
        if resp.question.response_type in ['scale', 'rating']:
            try:
                ratings.append(float(resp.response))
            except Exception:
                continue
    avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None

    # Funnel data
    funnel = {
        "registered": reg_count,
        "attended": att_count,
        "feedback_submitted": feedback_count,
    }

    # Optionally, add per-day or per-session breakdowns
    daily_breakdown = {}
    for session in sessions:
        day = session.date.isoformat()
        daily_breakdown.setdefault(day, {"sessions": 0, "registered": 0, "attended": 0, "feedback": 0})
        daily_breakdown[day]["sessions"] += 1
        regs_s = regs.filter(session=session)
        daily_breakdown[day]["registered"] += regs_s.count()
        daily_breakdown[day]["attended"] += regs_s.filter(attendance=True).count()
        qids = FeedbackQuestion.objects.filter(session=session).values_list('id', flat=True)
        daily_breakdown[day]["feedback"] += FeedbackResponse.objects.filter(question_id__in=qids).values('participant_id').distinct().count()

    return Response({
        "period": period,
        "date_from": start,
        "date_to": end,
        "total_sessions": total_sessions,
        "session_ids": session_ids, 
        "total_registered": reg_count,
        "total_attended": att_count,
        "feedback_count": feedback_count,
        "average_feedback_rating": avg_feedback_rating,
        "funnel": funnel,
        "daily_breakdown": daily_breakdown,
        "registered_participant_ids": registered_participant_ids,
        "attended_participant_ids": attended_participant_ids,
        "feedback_participant_ids": feedback_participant_ids,
    })