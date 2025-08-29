import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/app_footer.dart';
import 'session_detail_screen.dart';
import '../../services/api_service.dart';
import '../../utils/date_time_utils.dart';
import 'logged_session_detail_screen.dart';
import 'collect_feedback_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'session_materials_viewer_screen.dart';

typedef SessionListFetcher = Future<List<dynamic>> Function();

class AllSessionsScreen extends StatelessWidget {
  final int userId;

  const AllSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final upcoming = profile['upcoming_sessions'] ?? [];
        final past = profile['past_sessions'] ?? [];
        final registeredIds = Set<int>.from(
          (profile['registered_session'] ?? []).map((s) => s['id']),
        );
        final attendedIds = Set<int>.from(
          (profile['attended_sessions'] ?? []).map((s) => s['id']),
        );
        final feedbackIds = Set<int>.from(
          (profile['feedback_submitted_sessions'] ?? []).map((s) => s['id']),
        );
        return UserSessionListTemplate(
          userId: userId,
          title: 'All Sessions',
          fetchSessions: () async => [...upcoming, ...past],
          showRegisterButton: true,
          registeredSessionIds: registeredIds,
          attendedSessionIds: attendedIds,
          feedbackSubmittedSessionIds: feedbackIds,
        );
      },
    );
  }
}

class UpcomingSessionsScreen extends StatelessWidget {
  final int userId;
  const UpcomingSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final upcoming = profile['upcoming_sessions'] ?? [];
        final registeredIds = Set<int>.from(
          (profile['registered_session'] ?? []).map((s) => s['id']),
        );
        final attendedIds = Set<int>.from(
          (profile['attended_sessions'] ?? []).map((s) => s['id']),
        );
        final feedbackIds = Set<int>.from(
          (profile['feedback_submitted_sessions'] ?? []).map((s) => s['id']),
        );

        return UserSessionListTemplate(
          userId: userId,
          title: 'Upcoming Sessions',
          fetchSessions: () async => [...upcoming],
          showRegisterButton: true,
          registeredSessionIds: registeredIds,
          attendedSessionIds: attendedIds,
          feedbackSubmittedSessionIds: feedbackIds,
        );
      },
    );
  }
}

class PastSessionsScreen extends StatelessWidget {
  final int userId;
  const PastSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final past = profile['past_sessions'] ?? [];
        final registeredIds = Set<int>.from(
          (profile['registered_session'] ?? []).map((s) => s['id']),
        );
        final attendedIds = Set<int>.from(
          (profile['attended_sessions'] ?? []).map((s) => s['id']),
        );
        final feedbackIds = Set<int>.from(
          (profile['feedback_submitted_sessions'] ?? []).map((s) => s['id']),
        );

        return UserSessionListTemplate(
          userId: userId,
          title: 'Past Sessions',
          fetchSessions: () async => [...past],
          showRegisterButton: false,
          registeredSessionIds: registeredIds,
          attendedSessionIds: attendedIds,
          feedbackSubmittedSessionIds: feedbackIds,
        );
      },
    );
  }
}

class RegisteredUpcomingSessionsScreen extends StatelessWidget {
  final int userId;
  const RegisteredUpcomingSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final registeredUpcoming =
            profile['registered_upcoming_sessions'] ?? [];
        final registeredIds = Set<int>.from(
          (profile['registered_session'] ?? []).map((s) => s['id']),
        );
        final attendedIds = Set<int>.from(
          (profile['attended_sessions'] ?? []).map((s) => s['id']),
        );
        final feedbackIds = Set<int>.from(
          (profile['feedback_submitted_sessions'] ?? []).map((s) => s['id']),
        );

        return UserSessionListTemplate(
          userId: userId,
          title: 'Registered Upcoming Sessions',
          fetchSessions: () async => [...registeredUpcoming],
          showRegisterButton: false,
          registeredSessionIds: registeredIds,
          attendedSessionIds: attendedIds,
          feedbackSubmittedSessionIds: feedbackIds,
        );
      },
    );
  }
}

class UnregisteredUpcomingSessionsScreen extends StatelessWidget {
  final int userId;
  const UnregisteredUpcomingSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final unregisteredUpcoming =
            profile['unregistered_upcoming_sessions'] ?? [];
        final registeredIds = Set<int>.from(
          (profile['registered_session'] ?? []).map((s) => s['id']),
        );
        final attendedIds = Set<int>.from(
          (profile['attended_sessions'] ?? []).map((s) => s['id']),
        );
        final feedbackIds = Set<int>.from(
          (profile['feedback_submitted_sessions'] ?? []).map((s) => s['id']),
        );

        return UserSessionListTemplate(
          userId: userId,
          title: 'Unregistered Upcoming Sessions',
          fetchSessions: () async => [...unregisteredUpcoming],
          showRegisterButton: true,
          registeredSessionIds: registeredIds,
          attendedSessionIds: attendedIds,
          feedbackSubmittedSessionIds: feedbackIds,
        );
      },
    );
  }
}

class RegisteredPastSessionsScreen extends StatelessWidget {
  final int userId;
  const RegisteredPastSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final registeredPast = profile['registered_past_sessions'] ?? [];
        final registeredIds = Set<int>.from(
          (profile['registered_session'] ?? []).map((s) => s['id']),
        );
        final attendedIds = Set<int>.from(
          (profile['attended_sessions'] ?? []).map((s) => s['id']),
        );
        final feedbackIds = Set<int>.from(
          (profile['feedback_submitted_sessions'] ?? []).map((s) => s['id']),
        );

        return UserSessionListTemplate(
          userId: userId,
          title: 'Registered Past Sessions',
          fetchSessions: () async => [...registeredPast],
          showRegisterButton: false,
          registeredSessionIds: registeredIds,
          attendedSessionIds: attendedIds,
          feedbackSubmittedSessionIds: feedbackIds,
        );
      },
    );
  }
}

class AllRegisteredSessionsScreen extends StatelessWidget {
  final int userId;
  const AllRegisteredSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getRegisteredSessions(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final registeredSessions = snapshot.data!;
        // For attended and feedback status, fetch those sets as well if needed
        return FutureBuilder<List<dynamic>>(
          future: ApiService.getAttendedSessions(userId),
          builder: (context, attendedSnapshot) {
            final attendedIds =
                attendedSnapshot.hasData
                    ? attendedSnapshot.data!
                        .map<int>((s) => s['id'] as int)
                        .toSet()
                    : <int>{};
            return FutureBuilder<List<dynamic>>(
              future: ApiService.getFeedbackSubmittedSessions(userId),
              builder: (context, feedbackSnapshot) {
                final feedbackIds =
                    feedbackSnapshot.hasData
                        ? feedbackSnapshot.data!
                            .map<int>((s) => s['id'] as int)
                            .toSet()
                        : <int>{};
                final registeredIds =
                    registeredSessions.map<int>((s) => s['id'] as int).toSet();

                return UserSessionListTemplate(
                  userId: userId,
                  title: 'All Registered Sessions',
                  fetchSessions: () async => registeredSessions,
                  showRegisterButton: false,
                  registeredSessionIds: registeredIds,
                  attendedSessionIds: attendedIds,
                  feedbackSubmittedSessionIds: feedbackIds,
                );
              },
            );
          },
        );
      },
    );
  }
}

class AttendedSessionsScreen extends StatelessWidget {
  final int userId;
  const AttendedSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getAttendedSessions(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<List<dynamic>>(
          future: ApiService.getFeedbackSubmittedSessions(userId),
          builder: (context, feedbackSnapshot) {
            if (!feedbackSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final feedbackSessions = feedbackSnapshot.data!;
            final feedbackIds =
                feedbackSessions.map<int>((s) => s['id'] as int).toSet();
            final attended = snapshot.data!;
            final registeredIds =
                attended.map<int>((s) => s['id'] as int).toSet();
            final attendedIds =
                attended.map<int>((s) => s['id'] as int).toSet();

            return UserSessionListTemplate(
              userId: userId,
              title: 'Attended Sessions',
              fetchSessions: () async => attended,
              showRegisterButton: false,
              registeredSessionIds: registeredIds,
              attendedSessionIds: attendedIds,
              feedbackSubmittedSessionIds: feedbackIds,
            );
          },
        );
      },
    );
  }
}

class FeedbackNeededSessionsScreen extends StatelessWidget {
  final int userId;
  const FeedbackNeededSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Fetch all three lists in parallel
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getRegisteredSessions(userId),
      builder: (context, registeredSnapshot) {
        if (!registeredSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final registeredSessions = registeredSnapshot.data!;
        final registeredIds =
            registeredSessions.map<int>((s) => s['id'] as int).toSet();

        return FutureBuilder<List<dynamic>>(
          future: ApiService.getAttendedSessions(userId),
          builder: (context, attendedSnapshot) {
            if (!attendedSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final attendedSessions = attendedSnapshot.data!;
            final attendedIds =
                attendedSessions.map<int>((s) => s['id'] as int).toSet();

            return FutureBuilder<List<dynamic>>(
              future: ApiService.getFeedbackSubmittedSessions(userId),
              builder: (context, feedbackSnapshot) {
                if (!feedbackSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final feedbackSessions = feedbackSnapshot.data!;
                final feedbackSubmittedIds =
                    feedbackSessions.map<int>((s) => s['id'] as int).toSet();

                // Feedback needed: registered AND attended AND NOT feedback submitted
                final feedbackNeededSessions =
                    attendedSessions.where((session) {
                      final id = session['id'] as int;
                      return registeredIds.contains(id) &&
                          !feedbackSubmittedIds.contains(id);
                    }).toList();

                return UserSessionListTemplate(
                  userId: userId,
                  title: 'Sessions Needing Feedback',
                  fetchSessions: () async => feedbackNeededSessions,
                  showRegisterButton: false,
                  registeredSessionIds: registeredIds,
                  attendedSessionIds: attendedIds,
                  feedbackSubmittedSessionIds: feedbackSubmittedIds,
                );
              },
            );
          },
        );
      },
    );
  }
}

class UserSessionListTemplate extends StatefulWidget {
  final int userId;
  final String title;
  final SessionListFetcher fetchSessions;
  final bool showCalendar;
  final bool showRegisterButton;
  final Set<int>? registeredSessionIds;
  final Set<int>? attendedSessionIds;
  final Set<int>? feedbackSubmittedSessionIds;

  const UserSessionListTemplate({
    super.key,
    this.registeredSessionIds,
    this.attendedSessionIds,
    this.feedbackSubmittedSessionIds,
    required this.title,
    required this.userId,
    required this.fetchSessions,
    this.showCalendar = true,
    this.showRegisterButton = true,
  });

  @override
  State<UserSessionListTemplate> createState() =>
      _UserSessionListTemplateState();
}

class _UserSessionListTemplateState extends State<UserSessionListTemplate> {
  late Future<List<dynamic>> _sessionsFuture;
  String _searchQuery = '';
  List<DateTime> sessionDates = [];
  Map<DateTime, int> sessionDateToId = {};
  List<dynamic> materials = [];

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
  }

  Future<List<dynamic>> _loadSessions() async {
    final sessions = await widget.fetchSessions();
    sessions.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    sessionDates =
        sessions.map<DateTime>((s) => DateTime.parse(s['date'])).toList();
    sessionDateToId = {
      for (var s in sessions)
        DateTime.parse(s['date']).copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            ):
            s['id'],
    };
    return sessions;
  }

  Widget buildMaterialsSection() {
    if (materials.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No resource materials shared for this session.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Resource Materials',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        ...materials.map((mat) {
          final isFile = mat['file'] != null;
          final isUrl = mat['url'] != null && mat['url'].toString().isNotEmpty;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading:
                  isFile
                      ? Icon(Icons.insert_drive_file, color: Colors.blue)
                      : Icon(Icons.link, color: Colors.green),
              title: Text(
                mat['description'] ?? (isUrl ? mat['url'] : 'Material'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: isUrl ? Text(mat['url']) : null,
              trailing:
                  isFile
                      ? IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () {
                          // Optionally implement file download/open logic
                        },
                      )
                      : null,
              onTap:
                  isUrl
                      ? () async {
                        final url = Uri.parse(mat['url']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                      : null,
            ),
          );
        }),
      ],
    );
  }

  List<dynamic> _filterSessions(List<dynamic> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (s) =>
              (s['title'] ?? '').toLowerCase().contains(q) ||
              (s['location'] ?? '').toLowerCase().contains(q) ||
              (s['target_audience'] ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  void _showCalendarDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '${widget.title} Calendar',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: DateTime.now(),
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        eventLoader: (day) {
                          return sessionDates
                              .where(
                                (d) =>
                                    d.year == day.year &&
                                    d.month == day.month &&
                                    d.day == day.day,
                              )
                              .toList();
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          final normalized = DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            selectedDay.day,
                          );
                          final sessionId = sessionDateToId[normalized];
                          if (sessionId != null) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SessionDetailScreen(
                                      sessionId: sessionId,
                                    ),
                              ),
                            );
                          }
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                right: 1,
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.indigo,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final horizontalPadding = isMobile ? 8.0 : 32.0;
        final verticalPadding = isMobile ? 8.0 : 24.0;
        final cardPadding = isMobile ? 12.0 : 24.0;
        final titleFontSize = isMobile ? 18.0 : 22.0;
        final subtitleFontSize = isMobile ? 14.0 : 16.0;
        final chipFontSize = isMobile ? 12.0 : 14.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Colors.indigo,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  setState(() {
                    _sessionsFuture = _loadSessions();
                  });
                },
              ),
              if (widget.showCalendar)
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Calendar',
                  onPressed: () => _showCalendarDrawer(context),
                ),
            ],
          ),
          body: Container(
            color: Colors.indigo.shade50,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding / 2,
                    horizontal: horizontalPadding,
                  ),
                  child: ReusableSearchBar(
                    hintText: 'Search sessions',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _sessionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load sessions.\n${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No sessions available.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }

                      final sessions = _filterSessions(snapshot.data!);
                      if (sessions.isEmpty) {
                        return const Center(
                          child: Text(
                            'No sessions match your search.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          vertical: verticalPadding,
                          horizontal: horizontalPadding,
                        ),
                        itemCount: sessions.length,
                        separatorBuilder:
                            (_, __) => SizedBox(height: cardPadding),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final formattedDate = formatDateFromSession(session);
                          final formattedTime = formatTimeFromSession(session);
                          final isFeedbackSubmitted =
                              widget.feedbackSubmittedSessionIds != null &&
                              widget.feedbackSubmittedSessionIds!.contains(
                                int.tryParse(session['id'].toString()),
                              );

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final isPast =
                                  DateTime.tryParse(
                                    session['date_time'] ?? '',
                                  )?.isBefore(DateTime.now()) ??
                                  false;
                              final isRegistered =
                                  widget.registeredSessionIds?.contains(
                                    session['id'],
                                  ) ??
                                  false;
                              final showRegisterButton =
                                  widget.showRegisterButton &&
                                  !isRegistered &&
                                  !isPast;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => LoggedSessionDetailScreen(
                                        sessionId: session['id'],
                                        userId: widget.userId,
                                        showRegisterButton: showRegisterButton,
                                      ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(cardPadding / 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: isMobile ? 24 : 32,
                                          backgroundColor:
                                              Colors.indigo.shade100,
                                          child: Icon(
                                            Icons.event,
                                            color: Colors.indigo,
                                            size: isMobile ? 28 : 36,
                                          ),
                                        ),
                                        SizedBox(width: isMobile ? 12 : 24),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                session['workshop']?['title'] ??
                                                    session['workshop_title'] ??
                                                    session['title'] ??
                                                    'Session',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: titleFontSize,
                                                ),
                                              ),
                                              if (session['location'] != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        size: 16,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          session['location'],
                                                          style: TextStyle(
                                                            fontSize:
                                                                subtitleFontSize,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        fontSize:
                                                            subtitleFontSize,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Icon(
                                                      Icons.access_time,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formattedTime,
                                                      style: TextStyle(
                                                        fontSize:
                                                            subtitleFontSize,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (session['target_audience'] !=
                                                  null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.group,
                                                        size: 16,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          session['target_audience'],
                                                          style: TextStyle(
                                                            fontSize:
                                                                subtitleFontSize,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    if (widget.registeredSessionIds !=
                                                            null &&
                                                        widget
                                                            .registeredSessionIds!
                                                            .contains(
                                                              int.tryParse(
                                                                session['id']
                                                                    .toString(),
                                                              ),
                                                            ))
                                                      Chip(
                                                        label: Text(
                                                          'Registered',
                                                          style: TextStyle(
                                                            fontSize:
                                                                chipFontSize,
                                                          ),
                                                        ),
                                                        avatar: const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.blue,
                                                          size: 18,
                                                        ),
                                                        backgroundColor:
                                                            Colors.blue.shade50,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                    if (widget.attendedSessionIds !=
                                                            null &&
                                                        widget
                                                            .attendedSessionIds!
                                                            .contains(
                                                              int.tryParse(
                                                                session['id']
                                                                    .toString(),
                                                              ),
                                                            ))
                                                      Chip(
                                                        label: Text(
                                                          'Attended',
                                                          style: TextStyle(
                                                            fontSize:
                                                                chipFontSize,
                                                          ),
                                                        ),
                                                        avatar: const Icon(
                                                          Icons.verified,
                                                          color: Colors.green,
                                                          size: 18,
                                                        ),
                                                        backgroundColor:
                                                            Colors
                                                                .green
                                                                .shade50,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                    if (widget.feedbackSubmittedSessionIds !=
                                                            null &&
                                                        widget
                                                            .feedbackSubmittedSessionIds!
                                                            .contains(
                                                              int.tryParse(
                                                                session['id']
                                                                    .toString(),
                                                              ),
                                                            ))
                                                      Chip(
                                                        label: Text(
                                                          'Feedback Responses Submitted',
                                                          style: TextStyle(
                                                            fontSize:
                                                                chipFontSize,
                                                          ),
                                                        ),
                                                        avatar: const Icon(
                                                          Icons.feedback,
                                                          color: Colors.orange,
                                                          size: 18,
                                                        ),
                                                        backgroundColor:
                                                            Colors
                                                                .orange
                                                                .shade50,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              // Cancel Registration Button for registered upcoming sessions
                                              if (widget.registeredSessionIds !=
                                                      null &&
                                                  widget.registeredSessionIds!
                                                      .contains(
                                                        int.tryParse(
                                                          session['id']
                                                              .toString(),
                                                        ),
                                                      ) &&
                                                  (DateTime.tryParse(
                                                        session['date_time'] ??
                                                            '',
                                                      )?.isAfter(
                                                        DateTime.now(),
                                                      ) ??
                                                      false))
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12.0,
                                                      ),
                                                  child: Wrap(
                                                    spacing: 12,
                                                    runSpacing: 8,
                                                    children: [
                                                      // Cancel Registration Button
                                                      OutlinedButton.icon(
                                                        icon: const Icon(
                                                          Icons.cancel,
                                                          color: Colors.red,
                                                        ),
                                                        label: const Text(
                                                          'Cancel Registration',
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          side:
                                                              const BorderSide(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                        onPressed: () async {
                                                          final confirmed = await showDialog<
                                                            bool
                                                          >(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => AlertDialog(
                                                                  title: const Text(
                                                                    'Cancel Registration',
                                                                  ),
                                                                  content:
                                                                      const Text(
                                                                        'Are you sure you want to cancel your registration for this session?',
                                                                      ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () => Navigator.of(
                                                                            context,
                                                                          ).pop(
                                                                            false,
                                                                          ),
                                                                      child:
                                                                          const Text(
                                                                            'No',
                                                                          ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () => Navigator.of(
                                                                            context,
                                                                          ).pop(
                                                                            true,
                                                                          ),
                                                                      child: const Text(
                                                                        'Yes',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          );

                                                          if (confirmed ==
                                                              true) {
                                                            try {
                                                              final result = await ApiService.cancelSessionRegistration(
                                                                userId:
                                                                    widget
                                                                        .userId,
                                                                sessionId:
                                                                    int.tryParse(
                                                                      session['id']
                                                                          .toString(),
                                                                    ) ??
                                                                    session['id'],
                                                              );

                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      result['message'],
                                                                    ),
                                                                    backgroundColor:
                                                                        result['success']
                                                                            ? Colors.green
                                                                            : Colors.red,
                                                                  ),
                                                                );

                                                                if (result['success']) {
                                                                  // Reload the sessions to update the UI
                                                                  setState(() {
                                                                    widget.registeredSessionIds?.remove(
                                                                      int.tryParse(
                                                                        session['id']
                                                                            .toString(),
                                                                      ),
                                                                    );
                                                                  });
                                                                }
                                                              }
                                                            } catch (e) {
                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text(
                                                                      'Failed to cancel registration. Please try again.',
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else if ((widget.attendedSessionIds !=
                                                          null &&
                                                      widget.attendedSessionIds!
                                                          .contains(
                                                            int.tryParse(
                                                              session['id']
                                                                  .toString(),
                                                            ),
                                                          )) &&
                                                  (!isFeedbackSubmitted ||
                                                      true))
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12.0,
                                                      ),
                                                  child: Wrap(
                                                    spacing: 12,
                                                    runSpacing: 8,
                                                    children: [
                                                      if (!isFeedbackSubmitted)
                                                        OutlinedButton.icon(
                                                          icon: const Icon(
                                                            Icons.feedback,
                                                            color: Colors.green,
                                                          ),
                                                          label: const Text(
                                                            'Submit Feedback',
                                                          ),
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => CollectFeedbackScreen(
                                                                      sessionId:
                                                                          session['id'],
                                                                      participant: {
                                                                        'id':
                                                                            widget.userId,
                                                                      },
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      OutlinedButton.icon(
                                                        icon: const Icon(
                                                          Icons.folder,
                                                          color: Colors.indigo,
                                                        ),
                                                        label: const Text(
                                                          'View Materials',
                                                        ),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => Scaffold(
                                                                    appBar: AppBar(
                                                                      title: const Text(
                                                                        'Session Materials',
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .indigo,
                                                                    ),
                                                                    body: SessionMaterialsViewer(
                                                                      sessionId:
                                                                          int.tryParse(
                                                                            session['id'].toString(),
                                                                          ) ??
                                                                          session['id'],
                                                                    ),
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton:
              widget.showCalendar
                  ? FloatingActionButton(
                    onPressed: () => _showCalendarDrawer(context),
                    child: const Icon(Icons.calendar_month),
                  )
                  : null,
          bottomNavigationBar: const AppFooter(),
        );
      },
    );
  }
}
