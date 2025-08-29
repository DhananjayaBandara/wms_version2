import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'edit_trainer_screen.dart';
import 'create_feedback_question_screen.dart';
import 'feedback_question_list_screen.dart';
import 'trainer_questions_screen.dart';
import '../admin/session_details_screen.dart';
import '../../widgets/app_footer.dart';
import '../../utils/list_utils.dart';
import '../../utils/date_time_utils.dart';
import 'upload_material_widget.dart';
import 'session_materials_list.dart';

class TrainerDashboardScreen extends StatefulWidget {
  final int trainerId;
  const TrainerDashboardScreen({super.key, required this.trainerId});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  late Future<Map<String, dynamic>> _trainerFuture;

  @override
  void initState() {
    super.initState();
    _trainerFuture = ApiService.getTrainerDetails(widget.trainerId);
  }

  void _refreshTrainer() {
    setState(() {
      _trainerFuture = ApiService.getTrainerDetails(widget.trainerId);
    });
  }

  void _editTrainer(Map<String, dynamic> trainer) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTrainerScreen(trainerId: widget.trainerId),
      ),
    );
    if (updated != null) _refreshTrainer();
  }

  void _createFeedbackQuestionsForSession(int sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreateFeedbackQuestionScreen(trainerId: widget.trainerId),
        settings: RouteSettings(
          arguments: {
            'sessionId': sessionId,
            'lockSession': true, // Pass flag to lock session field
          },
        ),
      ),
    );
  }

  void _viewFeedbackResponses(int sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackQuestionListScreen(sessionId: sessionId),
      ),
    );
  }

  void _viewSessionDetails(int sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailsScreen(sessionId: sessionId),
      ),
    );
  }

  void _viewSessionQuestions(int sessionId, String sessionTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TrainerQuestionsScreen(
              sessionId: sessionId,
              sessionTitle: sessionTitle,
            ),
      ),
    );
  }

  void _showChangeCredentialDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: const Text('Change Username/Password'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'New Username',
                        ),
                      ),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: obscurePassword,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final username = usernameController.text.trim();
                        final password = passwordController.text;
                        if (username.isEmpty && password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter username or password to update.',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await ApiService.updateTrainerCredential(
                            trainerId: widget.trainerId,
                            username: username.isEmpty ? null : username,
                            password: password.isEmpty ? null : password,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Credential updated successfully.'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update failed: $e')),
                          );
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildTrainerInfoCard(Map<String, dynamic> trainer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trainer['name'] ?? 'Trainer',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit Details',
                  onPressed: () => _editTrainer(trainer),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_reset),
                  tooltip: 'Change Username/Password',
                  onPressed: () => _showChangeCredentialDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(),
            ListTile(
              leading: Icon(Icons.badge, color: Colors.blue.shade700),
              title: Text('Designation'),
              subtitle: Text(trainer['designation'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue.shade700),
              title: Text('Email'),
              subtitle: Text(trainer['email'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue.shade700),
              title: Text('Contact Number'),
              subtitle: Text(trainer['contact_number'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.star, color: Colors.blue.shade700),
              title: Text('Expertise'),
              subtitle: Text(trainer['expertise'] ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Details'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshTrainer,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _trainerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Failed to load trainer details.'));
          }
          final trainer = snapshot.data!;
          final sessions = trainer['sessions'] as List<dynamic>? ?? [];
          final indexedSessions = indexListElements(
            sessions,
            valueKey: 'session',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrainerInfoCard(trainer),
                const SizedBox(height: 24),
                Text(
                  'Assigned Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                indexedSessions.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'No sessions assigned.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                    : Column(
                      children: List.generate(indexedSessions.length, (idx) {
                        final session = indexedSessions[idx]['session'];
                        final sessionIndex = indexedSessions[idx]['index'];
                        final bool isMobile =
                            MediaQuery.of(context).size.width < 600;
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  sessionIndex.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              title: Text(
                                session['workshop_title'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (session['date_time'] != null)
                                    Text(
                                      'Date: ${formatDateString(session['date_time'])}',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  if (session['date_time'] != null)
                                    Text(
                                      'Time: ${formatTimeString(session['date_time'])}',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  if (session['location'] != null)
                                    Text('Location: ${session['location']}'),
                                  if (isMobile) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.add_comment,
                                            size: 18,
                                          ),
                                          label: const Text('Create Feedback'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.indigo.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          onPressed:
                                              () =>
                                                  _createFeedbackQuestionsForSession(
                                                    session['session_id'],
                                                  ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.forum,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          label: const Text(
                                            'Responses',
                                            style: TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.blue.shade300,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          onPressed:
                                              () => _viewFeedbackResponses(
                                                session['session_id'],
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.question_answer,
                                            size: 18,
                                            color: Colors.purple,
                                          ),
                                          label: const Text(
                                            'Questions',
                                            style: TextStyle(
                                              color: Colors.purple,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.purple.shade300,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          onPressed:
                                              () => _viewSessionQuestions(
                                                session['session_id'],
                                                session['workshop_title'] ??
                                                    'Session ${session['session_id']}',
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              isThreeLine: true,
                              onTap:
                                  () => _viewSessionDetails(
                                    session['session_id'],
                                  ),
                              trailing:
                                  isMobile
                                      ? null
                                      : Wrap(
                                        spacing: 6,
                                        runSpacing: 4,

                                        children: [
                                          ElevatedButton.icon(
                                            icon: Icon(
                                              Icons.add_comment,
                                              size: 18,
                                            ),
                                            label: Text('Create Feedback'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.indigo.shade600,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            onPressed:
                                                () =>
                                                    _createFeedbackQuestionsForSession(
                                                      session['session_id'],
                                                    ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: Icon(
                                              Icons.forum,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                            label: Text(
                                              'Responses',
                                              style: TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.blue.shade300,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            onPressed:
                                                () => _viewFeedbackResponses(
                                                  session['session_id'],
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: Icon(
                                              Icons.question_answer,
                                              size: 18,
                                              color: Colors.purple,
                                            ),
                                            label: Text(
                                              'Questions',
                                              style: TextStyle(
                                                color: Colors.purple,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.purple.shade300,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            onPressed:
                                                () => _viewSessionQuestions(
                                                  session['session_id'],
                                                  session['workshop_title'] ??
                                                      'Session ${session['session_id']}',
                                                ),
                                          ),
                                          ElevatedButton.icon(
                                            icon: Icon(
                                              Icons.upload_file,
                                              size: 18,
                                            ),
                                            label: Text('Materials'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.teal.shade600,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder: (ctx) {
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom:
                                                          MediaQuery.of(
                                                            ctx,
                                                          ).viewInsets.bottom,
                                                      left: 16,
                                                      right: 16,
                                                      top: 24,
                                                    ),
                                                    child: StatefulBuilder(
                                                      builder:
                                                          (
                                                            context,
                                                            setModalState,
                                                          ) => SingleChildScrollView(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Upload Resource Material',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                                UploadMaterialWidget(
                                                                  sessionId:
                                                                      session['session_id'],
                                                                  trainerId:
                                                                      widget
                                                                          .trainerId,
                                                                  onUploadSuccess:
                                                                      () => setModalState(
                                                                        () {},
                                                                      ),
                                                                ),
                                                                Divider(),
                                                                Text(
                                                                  'Uploaded Materials',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                                SessionMaterialsList(
                                                                  sessionId:
                                                                      session['session_id'],
                                                                  onMaterialRemoved:
                                                                      () => setModalState(
                                                                        () {},
                                                                      ),
                                                                ),
                                                                SizedBox(
                                                                  height: 24,
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
                                        ],
                                      ),
                            ),
                          ),
                        );
                      }),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
