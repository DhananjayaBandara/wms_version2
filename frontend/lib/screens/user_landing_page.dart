import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'participant/user_signup_screen.dart';
import 'participant/user_signin_screen.dart';
import 'participant/all_upcoming_sessions_screen.dart';
import 'package:frontend/screens/homepage.dart';
import '../../widgets/app_footer.dart';
import 'participant/session_detail_screen.dart';

class UserLandingPage extends StatefulWidget {
  const UserLandingPage({super.key});

  @override
  State<UserLandingPage> createState() => _UserLandingPageState();
}

class _UserLandingPageState extends State<UserLandingPage> {
  late Future<List<dynamic>> _upcomingSessions;

  @override
  void initState() {
    super.initState();
    _upcomingSessions = ApiService.getUpcomingSessions();
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildHeader() {
    var screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome to the National Workshop Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.04 + 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  fontFamily: 'Roboto',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Discover, register, and participate in upcoming workshops and sessions. '
          'Sign up or sign in to manage your registrations and feedback.',
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,

      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Sign Up'),
          onPressed: () => _navigate(context, UserSignupScreen()),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Sign In'),
          onPressed: () => _navigate(context, UserSigninScreen()),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.event_available),
          label: const Text('All Upcoming Events'),
          onPressed: () => _navigate(context, AllUpcomingSessionsScreen()),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.account_circle),
          label: const Text('View My Page'),
          onPressed: () => _navigate(context, HomeScreen()),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessionsList(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No upcoming sessions.'),
      );
    }
    final mostRecent = sessions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Most Recent Upcoming Sessions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        ...mostRecent.map((session) {
          final workshopTitle =
              session['workshop']?['title'] ??
              session['workshop_title'] ??
              'Workshop';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            child: ListTile(
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
            ),
          );
        }),
        const Divider(),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('See All'),
            onPressed: () => _navigate(context, AllUpcomingSessionsScreen()),
          ),
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/1/10/ICTA_LOGO.gif',
        ),
        title: const Text(
          'User Portal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Sign Up'),
            onPressed: () => _navigate(context, UserSignupScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Sign In'),
            onPressed: () => _navigate(context, UserSigninScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildActionButtons(),
          FutureBuilder<List<dynamic>>(
            future: _upcomingSessions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Failed to load sessions: ${snapshot.error}'),
                );
              }
              final sessions = snapshot.data ?? [];
              return _buildUpcomingSessionsList(sessions);
            },
          ),
          const SizedBox(height: 30),
          Card(
            color: Colors.indigo.shade50,
            margin: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How to Use This Portal?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Sign up to create your account.\n'
                    '• Sign in to manage your profile and registrations.\n'
                    '• Browse and register for upcoming sessions.\n'
                    '• View your page to see your registrations and feedback.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigate(context, HomeScreen()),
        tooltip: 'My Page',
        child: const Icon(Icons.account_circle),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
