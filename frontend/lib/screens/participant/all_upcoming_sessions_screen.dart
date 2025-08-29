import 'package:flutter/material.dart';
import 'package:frontend/screens/participant/user_signin_screen.dart';
import 'package:frontend/screens/participant/session_detail_screen.dart';
import '../../services/api_service.dart';

class AllUpcomingSessionsScreen extends StatelessWidget {
  const AllUpcomingSessionsScreen({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Upcoming Sessions'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getUpcomingSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load sessions: ${snapshot.error}'),
            );
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('No upcoming sessions.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final session = sessions[i];
              final workshopTitle =
                  session['workshop']?['title'] ??
                  session['workshop_title'] ??
                  'Workshop';

              return ListTile(
                leading: const Icon(Icons.event, color: Colors.indigo),
                title: Text(workshopTitle ?? 'Session'),
                subtitle: Text(
                  'Workshop: $workshopTitle\n'
                  'Date: ${session['date_time']?.substring(0, 10) ?? ''}\n'
                  'Location: ${session['location'] ?? ''}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SessionDetailScreen(sessionId: session['id']),
                    ),
                  );
                },
                trailing: OutlinedButton(
                  child: const Text('Register'),
                  onPressed: () => _navigate(context, UserSigninScreen()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
