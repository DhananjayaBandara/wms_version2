import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'edit_session_screen.dart';
import 'create_session_screen.dart';
import 'session_details_screen.dart';
import '../participant/mark_attendance_screen.dart';
import '../trainer/feedback_question_list_screen.dart';
import '../participant/collect_feedback_screen.dart';
import 'session_dashboard_screen.dart';
import '../../widgets/search_bar.dart';
import '../../utils/qr_code.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';
import '../../utils/date_time_utils.dart';
import 'admin_comments_screen.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  _SessionListScreenState createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  late Future<List<dynamic>> _sessionsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    _sessionsFuture = ApiService.getSessions();
  }

  void _deleteSession(int sessionId) async {
    final success = await ApiService.deleteSession(sessionId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session deleted successfully!')),
      );
      _refreshList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete session!')),
      );
    }
  }

  void _confirmDeleteSession(int sessionId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this session?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSession(sessionId);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _refreshList() {
    setState(() {
      _loadSessions();
    });
  }

  List<dynamic> _filterSessions(List<dynamic> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (s) =>
              (s['id'].toString()).contains(q) ||
              (s['location'] ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            tooltip: 'Add Session',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateSessionScreen()),
              );
              _refreshList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ReusableSearchBar(
            hintText: 'Search sessions',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data ?? [];
                final filtered = _filterSessions(data);

                if (filtered.isEmpty) {
                  return const Center(child: Text('No sessions available.'));
                }

                final indexedSessions = indexListElements(
                  filtered,
                  valueKey: 'session',
                );

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: indexedSessions.length,
                  itemBuilder: (context, index) {
                    final indexed = indexedSessions[index];
                    final session = indexed['session'];
                    final sessionIndex = indexed['index'];
                    return SessionCard(
                      session: session,
                      index: sessionIndex,
                      onDelete: () => _confirmDeleteSession(session['id']),
                      onEdit: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EditSessionScreen(sessionId: session['id']),
                          ),
                        );
                        _refreshList();
                      },
                      onView:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SessionDetailsScreen(
                                    sessionId: session['id'],
                                  ),
                            ),
                          ),
                      onMarkAttendance: () {
                        if (session['token'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MarkAttendanceScreen(
                                    sessionToken: session['token'],
                                  ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session token is missing.'),
                            ),
                          );
                        }
                      },
                      onPreviewQr: () {
                        if (session['token'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => QrCodePreviewScreen(
                                    sessionToken: session['token'],
                                    sessionId: session['id'],
                                  ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session token is missing.'),
                            ),
                          );
                        }
                      },
                      onViewFeedbackQuestions: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FeedbackQuestionListScreen(
                                  sessionId: session['id'],
                                ),
                          ),
                        );
                      },
                      onCollectFeedback: () async {
                        String? nic = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final nicController = TextEditingController();
                            return AlertDialog(
                              title: const Text('Enter NIC'),
                              content: TextField(
                                controller: nicController,
                                decoration: const InputDecoration(
                                  labelText: 'NIC',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final nicVal = nicController.text.trim();
                                    if (nicVal.isNotEmpty) {
                                      Navigator.pop(context, nicVal);
                                    }
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );

                        if (nic != null && nic.isNotEmpty) {
                          final participant =
                              await ApiService.getParticipantByNIC(nic);
                          if (participant != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CollectFeedbackScreen(
                                      sessionId: session['id'],
                                      participant: participant,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No participant found for this NIC.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      onViewDashboard: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SessionDashboardScreen(
                                  sessionId: session['id'],
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onMarkAttendance;
  final VoidCallback onPreviewQr;
  final VoidCallback onViewFeedbackQuestions;
  final VoidCallback onCollectFeedback;
  final VoidCallback onViewDashboard;

  const SessionCard({
    required this.session,
    required this.index,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
    required this.onMarkAttendance,
    required this.onPreviewQr,
    required this.onViewFeedbackQuestions,
    required this.onCollectFeedback,
    required this.onViewDashboard,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            index.toString(),
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session['workshop'] != null && session['workshop']['title'] != null
              ? session['workshop']['title']
              : 'Workshop',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session['date'] != null)
              Text(
                'Date: ${formatDateFromSession(session)}',
                style: const TextStyle(fontSize: 14),
              ),
            if (session['time'] != null)
              Text(
                'Time: ${formatTimeFromSession(session)}',
                style: const TextStyle(fontSize: 14),
              ),
            Text(
              'Location: ${session['location'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 14),
            ),
            if (isMobile)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit, color: Colors.indigo),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      tooltip: 'Admin Comments',
                      icon: const Icon(Icons.comment, color: Colors.green),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AdminCommentsScreen(
                                  sessionId: session['id'],
                                  sessionTitle:
                                      session['workshop']?['title'] ??
                                      'Session ${session['id']}',
                                ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Mark Attendance by Admin',
                      icon: const Icon(Icons.qr_code, color: Colors.deepPurple),
                      onPressed: onMarkAttendance,
                    ),
                    IconButton(
                      tooltip: 'Preview QR Code to Mark Attendance',
                      icon: const Icon(
                        Icons.qr_code_2,
                        color: Colors.deepPurple,
                      ),
                      onPressed: onPreviewQr,
                    ),
                    IconButton(
                      tooltip: 'View Feedback Questions',
                      icon: const Icon(Icons.list, color: Colors.orange),
                      onPressed: onViewFeedbackQuestions,
                    ),
                    IconButton(
                      tooltip: 'Collect Feedback',
                      icon: const Icon(Icons.feedback, color: Colors.teal),
                      onPressed: onCollectFeedback,
                    ),
                    IconButton(
                      tooltip: 'Session Dashboard',
                      icon: const Icon(Icons.bar_chart, color: Colors.green),
                      onPressed: onViewDashboard,
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
          ],
        ),

        onTap: onView,
        trailing:
            isMobile
                ? null
                : SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          tooltip: 'Admin Comments',
                          icon: const Icon(Icons.comment, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AdminCommentsScreen(
                                      sessionId: session['id'],
                                      sessionTitle:
                                          session['workshop']?['title'] ??
                                          'Session ${session['id']}',
                                    ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Mark Attendance by Admin',
                          icon: const Icon(
                            Icons.qr_code,
                            color: Colors.deepPurple,
                          ),
                          onPressed: onMarkAttendance,
                        ),
                        IconButton(
                          tooltip: 'Preview QR Code to Mark Attendance',
                          icon: const Icon(
                            Icons.qr_code_2,
                            color: Colors.deepPurple,
                          ),
                          onPressed: onPreviewQr,
                        ),
                        IconButton(
                          tooltip: 'View Feedback Questions',
                          icon: const Icon(Icons.list, color: Colors.orange),
                          onPressed: onViewFeedbackQuestions,
                        ),
                        IconButton(
                          tooltip: 'Collect Feedback',
                          icon: const Icon(Icons.feedback, color: Colors.teal),
                          onPressed: onCollectFeedback,
                        ),

                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
