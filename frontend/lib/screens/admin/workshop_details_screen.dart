import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../template/details_screen.dart';
import '../../utils/list_utils.dart';
import 'session_details_screen.dart';
import 'participant_details_screen.dart';
import 'admin_comments_screen.dart';

class WorkshopDetailsScreen extends StatelessWidget {
  final int workshopId;

  const WorkshopDetailsScreen({super.key, required this.workshopId});

  // Function to fetch workshop details
  Future<Map<String, dynamic>> fetchWorkshopDetails(int workshopId) async {
    try {
      final workshop = await ApiService.getWorkshopDetails(workshopId);
      return workshop;
    } catch (e) {
      throw Exception('Failed to load workshop details');
    }
  }

  void _navigateToAdminComments(
    BuildContext context,
    int sessionId,
    String sessionTitle,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminCommentsScreen(
              sessionId: sessionId,
              sessionTitle: sessionTitle,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScreenTemplate(
      screenTitle: 'Workshop Details',
      fetchData: fetchWorkshopDetails,
      itemId: workshopId,
      titleAtTop: 'Workshop Overview',
      dynamicTitleKey: 'title',
      detailItems: [
        DetailItem(
          title: 'Workshop Title',
          icon: '0xe668',
          subtitle: (data) => data['title'] ?? 'Untitled Workshop',
        ),
        DetailItem(
          title: 'Description',
          icon: '0xf580',
          subtitle: (data) => data['description'] ?? 'No description provided.',
        ),
      ],
      sections: [
        Section(
          title: '📅 Sessions',
          builder: (data) {
            final sessions = data['sessions'] ?? [];
            final indexedSessions = indexListElements(
              sessions,
              valueKey: 'session',
            );
            return indexedSessions.isEmpty
                ? const Text('No sessions scheduled.')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: indexedSessions.length,
                  itemBuilder: (context, index) {
                    final session = indexedSessions[index]['session'];
                    final sessionIndex = indexedSessions[index]['index'];
                    int? sessionId;
                    if (session['id'] != null) {
                      sessionId =
                          session['id'] is int
                              ? session['id']
                              : int.tryParse(session['id'].toString());
                    } else if (session.containsKey('session_id')) {
                      sessionId =
                          session['session_id'] is int
                              ? session['session_id']
                              : int.tryParse(session['session_id'].toString());
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              sessionIndex.toString(),
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${session['date']} | ${session['time']}',
                          ),
                          subtitle: Text(session['location'] ?? 'No location'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.comment,
                              color: Colors.deepPurple,
                            ),
                            tooltip: 'View Comments',
                            onPressed:
                                sessionId != null
                                    ? () => _navigateToAdminComments(
                                      context,
                                      sessionId!,
                                      'Session ${session['title'] ?? sessionIndex}',
                                    )
                                    : null,
                          ),
                          onTap:
                              sessionId != null
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => SessionDetailsScreen(
                                              sessionId: sessionId!,
                                            ),
                                      ),
                                    );
                                  }
                                  : null,
                        ),
                      ),
                    );
                  },
                );
          },
        ),
        Section(
          title: '👥 Registered Participants',
          builder: (data) {
            final participants = data['participants'] ?? [];
            final indexedParticipants = indexListElements(
              participants,
              valueKey: 'participant',
            );
            return indexedParticipants.isEmpty
                ? const Text('No participants registered.')
                : Column(
                  children: List.generate(indexedParticipants.length, (index) {
                    final participant =
                        indexedParticipants[index]['participant'];
                    final participantIndex =
                        indexedParticipants[index]['index'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              participantIndex.toString(),
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(participant['name'] ?? 'Unnamed'),
                          subtitle: Text(participant['email'] ?? 'No email'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ParticipantDetailsScreen(
                                      participant: participant,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                );
          },
        ),
      ],
    );
  }
}
