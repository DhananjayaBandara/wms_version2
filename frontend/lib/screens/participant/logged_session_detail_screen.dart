import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/session.dart';
import '../../widgets/app_footer.dart';
import '../../utils/date_time_utils.dart';

class LoggedSessionDetailScreen extends StatefulWidget {
  final int sessionId;
  final int userId;
  final bool showRegisterButton;

  const LoggedSessionDetailScreen({
    required this.sessionId,
    required this.userId,
    this.showRegisterButton = true,
    super.key,
  });

  @override
  _LoggedSessionDetailScreenState createState() =>
      _LoggedSessionDetailScreenState();
}

class _LoggedSessionDetailScreenState extends State<LoggedSessionDetailScreen> {
  Session? sessionData;
  bool isLoading = true;
  bool isRegistering = false;

  @override
  void initState() {
    super.initState();
    loadSessionDetails();
  }

  void loadSessionDetails() async {
    final data = await ApiService.getSessionById(widget.sessionId);
    setState(() {
      sessionData = Session.fromJson(data);
      isLoading = false;
    });
  }

  Future<void> _registerForSession() async {
    setState(() => isRegistering = true);
    final result = await ApiService.registerUserForSession(
      userId: widget.userId,
      sessionId: widget.sessionId,
    );
    setState(() => isRegistering = false);

    if (result['success']) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Success'),
              content: Text(result['message']),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(
                      context,
                    ).pop(true); // Return to refresh profile
                  },
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Registration Failed'),
              content: Text(result['message']),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        sessionData!.workshop.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          buildInfoCard(
                            Icons.description,
                            "Description",
                            sessionData!.workshop.description,
                          ),
                          buildInfoCard(
                            Icons.confirmation_number,
                            "Session ID",
                            '${sessionData!.id}',
                          ),
                          buildInfoCard(
                            Icons.place,
                            "Location",
                            sessionData!.location,
                          ),
                          buildInfoCard(
                            Icons.calendar_today,
                            "Date",
                            formatDateString(sessionData!.date),
                          ),
                          buildInfoCard(
                            Icons.access_time,
                            "Time",
                            formatTimeString(sessionData!.time),
                          ),
                          if (sessionData!.trainers.isNotEmpty)
                            buildInfoCard(
                              Icons.person,
                              "Trainers",
                              sessionData!.trainers
                                  .map((t) => t.name)
                                  .join('\n'),
                            ),
                          const SizedBox(height: 24),
                          if (widget.showRegisterButton)
                            ElevatedButton.icon(
                              icon: Icon(Icons.app_registration),
                              style: ElevatedButton.styleFrom(
                                iconColor: Colors.white,
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                elevation: 5,
                              ),
                              onPressed:
                                  isRegistering ? null : _registerForSession,
                              label:
                                  isRegistering
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Register for this Session',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: AppFooter(),
    );
  }

  Widget buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(color: Colors.black87)),
      ),
    );
  }
}
