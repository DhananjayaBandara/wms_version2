import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/participant/question_chat_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/app_footer.dart';
import 'edit_user_profile_screen.dart';
import 'user_signin_screen.dart';
import 'user_session_list_template.dart';
import 'logged_session_detail_screen.dart';
import 'collect_feedback_screen.dart';
import 'session_materials_viewer_screen.dart';
import 'qr_scan_attendance_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // ...
  void markAttendanceViaQR(int sessionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QRScanAttendanceScreen(participantId: widget.userId),
      ),
    );
    if (result != null && result.toString().toLowerCase().contains('success')) {
      setState(() {
        _attendedSessionIds.add(sessionId);
      });
    }
    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.toString())));
    }
  }

  late Future<Map<String, dynamic>> _profileFuture;
  List<Map<String, dynamic>> _todaysSessions = [];
  Set<int> _registeredSessionIds = {};
  final Set<int> _attendedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getUserProfile(widget.userId);
    _fetchNotifications();
    _fetchTodaysSessions();
  }

  void _fetchTodaysSessions() async {
    final profile = await ApiService.getUserProfile(widget.userId);
    final List<Map<String, dynamic>> sessions = [];
    for (var k in [
      'all_sessions',
      'upcoming_sessions',
      'registered_upcoming_sessions',
      'unregistered_upcoming_sessions',
      'past_sessions',
      'registered_past_sessions',
      'attended_sessions',
      'feedback_needed_sessions',
      'registered_all_sessions',
    ]) {
      if (profile[k] is List) {
        for (var s in profile[k]) {
          if (s is Map<String, dynamic>) sessions.add(s);
        }
      }
    }
    final seen = <dynamic>{};
    final unique = sessions.where((s) => seen.add(s['id'])).toList();
    final today = DateTime.now();
    final todaySessions =
        unique.where((s) {
          final dtStr = s['date_time'] ?? '';
          final dt = DateTime.tryParse(dtStr);
          return dt != null &&
              dt.year == today.year &&
              dt.month == today.month &&
              dt.day == today.day;
        }).toList();
    // Extract registered session IDs (try multiple possible keys)
    Set<int> registeredIds = {};
    if (profile['registered_sessions'] is List) {
      registeredIds =
          (profile['registered_sessions'] as List)
              .where((s) => s is Map<String, dynamic> && s['id'] != null)
              .map<int>((s) => s['id'] as int)
              .toSet();
    } else if (profile['registered_all_sessions'] is List) {
      registeredIds =
          (profile['registered_all_sessions'] as List)
              .where((s) => s is Map<String, dynamic> && s['id'] != null)
              .map<int>((s) => s['id'] as int)
              .toSet();
    } else if (profile['registered_session'] is List) {
      registeredIds =
          (profile['registered_session'] as List)
              .where((s) => s is Map<String, dynamic> && s['id'] != null)
              .map<int>((s) => s['id'] as int)
              .toSet();
    }
    setState(() {
      _todaysSessions = todaySessions;
      _registeredSessionIds = registeredIds;
    });
  }

  void _showProfileDialog(Map<String, dynamic> user) async {
    dynamic properties = user['properties'];
    Map<String, dynamic> propertiesMap = {};
    if (properties is String) {
      try {
        propertiesMap =
            properties.isNotEmpty
                ? Map<String, dynamic>.from(jsonDecode(properties))
                : {};
      } catch (_) {}
    } else if (properties is Map<String, dynamic>) {
      propertiesMap = properties;
    }

    // Fetch user types to get the correct property list for the selected user type
    List<dynamic> userTypes = [];
    try {
      userTypes = await ApiService.getParticipantTypes();
    } catch (_) {}

    // Find the selected user type and its properties
    final userTypeId =
        user['participant_type_id'] ?? user['participant_type']?['id'];
    final userType = userTypes.firstWhere(
      (t) => t['id'] == userTypeId,
      orElse: () => null,
    );
    final List<String> userTypeProperties =
        userType != null && userType['properties'] is List
            ? List<String>.from(userType['properties'])
            : [];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  color: Colors.indigo,
                  size: 32,
                ),
                const SizedBox(width: 8),
                const Text('User Info'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('NAME', user['name']),
                  _buildInfoRow('EMAIL', user['email']),
                  _buildInfoRow('NIC', user['nic']),
                  _buildInfoRow('CONTACT NUMBER', user['contact_number']),
                  _buildInfoRow('DISTRICT', user['district']),
                  _buildInfoRow('GENDER', user['gender']),
                  _buildInfoRow('USER TYPE', user['participant_type']?['name']),
                  if (userTypeProperties.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...userTypeProperties.map(
                      (key) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right,
                              size: 18,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${key.replaceAll('_', ' ').toUpperCase()}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          propertiesMap[key]?.toString() ?? '',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => EditUserProfileScreen(
                            user: user,
                            userId: widget.userId,
                          ),
                    ),
                  );
                  if (updated == true) {
                    setState(() {
                      _profileFuture = ApiService.getUserProfile(widget.userId);
                    });
                  }
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value != null ? value.toString() : '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => UserSigninScreen()),
      (route) => false,
    );
  }

  void _navigateToSessions(BuildContext context, String type) {
    Widget screen;
    switch (type) {
      case 'all':
        screen = AllSessionsScreen(userId: widget.userId);
        break;
      case 'upcoming':
        screen = UpcomingSessionsScreen(userId: widget.userId);
        break;
      case 'registered_upcoming':
        screen = RegisteredUpcomingSessionsScreen(userId: widget.userId);
        break;
      case 'unregistered_upcoming':
        screen = UnregisteredUpcomingSessionsScreen(userId: widget.userId);
        break;
      case 'past':
        screen = PastSessionsScreen(userId: widget.userId);
        break;
      case 'registered_past':
        screen = RegisteredPastSessionsScreen(userId: widget.userId);
        break;
      case 'registered_all':
        screen = AllRegisteredSessionsScreen(userId: widget.userId);
        break;
      case 'attended':
        screen = AttendedSessionsScreen(userId: widget.userId);
        break;
      case 'feedback_needed':
        screen = FeedbackNeededSessionsScreen(userId: widget.userId);
        break;
      default:
        screen = AllSessionsScreen(userId: widget.userId);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<Map<String, int>> _fetchSessionCounts(int userId) async {
    final profile = await ApiService.getUserProfile(userId);
    final attendedSessions = await ApiService.getAttendedSessions(userId);
    final feedbackSubmittedSessions =
        await ApiService.getFeedbackSubmittedSessions(userId);
    final registeredSessions = await ApiService.getRegisteredSessions(userId);

    final registeredIds =
        registeredSessions.map<int>((s) => s['id'] as int).toSet();
    final attendedIds =
        attendedSessions.map<int>((s) => s['id'] as int).toSet();
    final feedbackSubmittedIds =
        feedbackSubmittedSessions.map<int>((s) => s['id'] as int).toSet();

    final feedbackNeededCount =
        attendedIds
            .where(
              (id) =>
                  registeredIds.contains(id) &&
                  !feedbackSubmittedIds.contains(id),
            )
            .length;

    return {
      'all':
          (profile['upcoming_sessions']?.length ?? 0) +
          (profile['past_sessions']?.length ?? 0),
      'upcoming': profile['upcoming_sessions']?.length ?? 0,
      'registeredUpcoming':
          profile['registered_upcoming_sessions']?.length ?? 0,
      'unregisteredUpcoming':
          profile['unregistered_upcoming_sessions']?.length ?? 0,
      'past': profile['past_sessions']?.length ?? 0,
      'registeredPast': profile['registered_past_sessions']?.length ?? 0,
      'attended': attendedSessions.length,
      'feedbackNeeded': feedbackNeededCount,
      'feedbackSubmitted': feedbackSubmittedSessions.length,
      'registeredAll': registeredSessions.length,
    };
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(String nic) {
    final nicController = TextEditingController(text: nic);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Change Password'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nicController,
                        decoration: const InputDecoration(labelText: 'NIC'),
                        readOnly: true, // Make it read-only
                      ),
                      TextFormField(
                        controller: currentPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                        ),
                        obscureText: true,
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                        ),
                        obscureText: true,
                        validator:
                            (v) =>
                                v == null || v.length < 8
                                    ? 'Min 8 characters'
                                    : null,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => loading = true);
                              final nic = nicController.text.trim();
                              final currentPassword =
                                  currentPasswordController.text;
                              final newPassword = newPasswordController.text;
                              try {
                                final response =
                                    await ApiService.changePassword(
                                      nic: nic,
                                      currentPassword: currentPassword,
                                      newPassword: newPassword,
                                    );
                                if (response['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password changed successfully!',
                                      ),
                                    ),
                                  );
                                  _logout();
                                } else {
                                  setState(() => loading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response['error'] ??
                                            'Failed to change password',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => loading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                    child:
                        loading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Change'),
                  ),
                ],
              ),
        );
      },
    );
  }

  List<dynamic> _notifications = [];
  bool _loadingNotifications = false;
  int get _unreadNotificationCount =>
      _notifications.where((n) => !(n['is_read'] ?? false)).length;

  Future<void> _fetchNotifications() async {
    setState(() => _loadingNotifications = true);
    try {
      final notifications = await ApiService.getNotifications(widget.userId);
      // Map backend response to expected display format
      setState(() {
        _notifications =
            notifications
                .map(
                  (n) => {
                    'id': n['id'],
                    'is_read': n['is_read'],
                    'created_at': n['created_at'],
                    'title': n['template']?['title'] ?? '',
                    'message': n['template']?['message'] ?? '',
                    'url': n['template']?['url'] ?? '',
                    'notification_type':
                        n['template']?['notification_type'] ?? '',
                  },
                )
                .toList();
        _loadingNotifications = false;
      });
    } catch (_) {
      setState(() => _loadingNotifications = false);
    }
  }

  void _showNotificationsDialog() async {
    await _fetchNotifications();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notifications'),
            content: SizedBox(
              width: 350,
              child:
                  _loadingNotifications
                      ? const Center(child: CircularProgressIndicator())
                      : _notifications.isEmpty
                      ? const Text('No notifications.')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return ListTile(
                            leading: Icon(
                              n['is_read']
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: n['is_read'] ? Colors.grey : Colors.indigo,
                            ),
                            title: Text(n['title'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n['message'] ?? ''),
                                if (n['created_at'] != null &&
                                    n['created_at'].isNotEmpty)
                                  Text(
                                    n['created_at']
                                        .toString()
                                        .replaceFirst('T', ' ')
                                        .substring(0, 16),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                n['is_read']
                                    ? null
                                    : const Icon(
                                      Icons.circle,
                                      color: Colors.red,
                                      size: 10,
                                    ),
                            onTap: () async {
                              await ApiService.markNotificationRead(n['id']);
                              Navigator.of(context).pop();
                              await _fetchNotifications();
                              final url = n['url'];
                              if (url != null && url.isNotEmpty) {
                                _handleNotificationNavigation(url);
                              }
                            },
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _handleNotificationNavigation(String url) {
    // Remove any leading/trailing slashes for consistency
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    final segments = cleanUrl.split('/');

    if (segments.isEmpty) return;

    // Use a post-frame callback to ensure navigation after dialog closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (segments[0] == 'sessions' && segments.length >= 2) {
        final sessionId = int.tryParse(segments[1]);
        if (sessionId == null) return;

        if (segments.length == 3) {
          // /sessions/<id>/  -> Session detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => LoggedSessionDetailScreen(
                    sessionId: sessionId,
                    userId: widget.userId,
                    showRegisterButton: true,
                  ),
            ),
          );
        } else if (segments.length >= 4 && segments[2] == 'feedback') {
          // /sessions/<id>/feedback/ -> Collect feedback
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CollectFeedbackScreen(
                    sessionId: sessionId,
                    participant: {'id': widget.userId},
                  ),
            ),
          );
        } else if (segments.length >= 4 && segments[2] == 'materials') {
          // /sessions/<id>/materials/ -> Session materials
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionMaterialsViewer(sessionId: sessionId),
            ),
          );
        } else {
          // Handle other session-related URLs if needed
        }
      } else {
        // Handle other types of URLs, e.g., workshops, events, etc.
        // You can add more navigation logic here as needed
        // For unknown URLs, you might show a snackbar or do nothing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No navigation available for this notification.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _profileFuture = ApiService.getUserProfile(widget.userId);
                _attendedSessionIds;
                _registeredSessionIds;
                _fetchTodaysSessions();
                _fetchNotifications();
                _fetchSessionCounts(widget.userId);
              });
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: _showNotificationsDialog,
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                  onPressed: null,
                );
              }
              final user = snapshot.data!['participant'] ?? {};
              return IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () => _showProfileDialog(user),
                tooltip: 'User Info',
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.account_circle,
                      size: 48,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'User Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('All Sessions'),
              onTap: () => _navigateToSessions(context, 'all'),
            ),
            ListTile(
              leading: const Icon(Icons.upcoming),
              title: const Text('Upcoming Sessions'),
              onTap: () => _navigateToSessions(context, 'upcoming'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Registered Upcoming Sessions'),
              onTap: () => _navigateToSessions(context, 'registered_upcoming'),
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Unregistered Upcoming Sessions'),
              onTap:
                  () => _navigateToSessions(context, 'unregistered_upcoming'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Past Sessions'),
              onTap: () => _navigateToSessions(context, 'past'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text('Registered Past Sessions'),
              onTap: () => _navigateToSessions(context, 'registered_past'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Attended Sessions'),
              onTap: () => _navigateToSessions(context, 'attended'),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Sessions Needing Feedback'),
              onTap: () => _navigateToSessions(context, 'feedback_needed'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change Password'),
              onTap: () async {
                Navigator.pop(context);
                // Fetch the profile to get the NIC
                final profile = await ApiService.getUserProfile(widget.userId);
                final nic = profile['participant']?['nic'] ?? '';
                _showChangePasswordDialog(nic);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _logout();
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _fetchSessionCounts(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final counts = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossAxisCount = isMobile ? 1 : 3;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_todaysSessions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Today's Sessions",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _todaysSessions.length,
                        itemBuilder: (context, idx) {
                          final session = _todaysSessions[idx];
                          final sessionId = session['id'] as int;
                          final hasAttended = _attendedSessionIds.contains(
                            sessionId,
                          );
                          final isRegistered = _registeredSessionIds.contains(
                            sessionId,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                session['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(session['location'] ?? ''),
                              trailing:
                                  !hasAttended
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isRegistered)
                                            ElevatedButton.icon(
                                              icon: const Icon(
                                                Icons.qr_code_scanner,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'QR Attendance',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurple,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed:
                                                  () => markAttendanceViaQR(
                                                    sessionId,
                                                  ),
                                            )
                                          else
                                            ElevatedButton.icon(
                                              icon: const Icon(
                                                Icons.app_registration,
                                                size: 16,
                                              ),
                                              label: const Text('Register'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed:
                                                  () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              LoggedSessionDetailScreen(
                                                                sessionId:
                                                                    sessionId,
                                                                userId:
                                                                    widget
                                                                        .userId,
                                                              ),
                                                    ),
                                                  ),
                                            ),
                                        ],
                                      )
                                      : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => LoggedSessionDetailScreen(
                                          sessionId: sessionId,
                                          userId: widget.userId,
                                        ),
                                  ),
                                );
                              },
                              onLongPress: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => QuestionChatScreen(
                                          sessionId: sessionId,
                                          participantId: widget.userId,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionTitle('My Dashboard'),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _buildSummaryCard(
                          context,
                          title: 'All Sessions',
                          count: counts['all'] ?? 0,
                          icon: Icons.event,
                          color: Colors.indigo,
                          onTap: () => _navigateToSessions(context, 'all'),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Upcoming Sessions',
                          count: counts['upcoming'] ?? 0,
                          icon: Icons.upcoming,
                          color: Colors.blue,
                          onTap: () => _navigateToSessions(context, 'upcoming'),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Registered Upcoming',
                          count: counts['registeredUpcoming'] ?? 0,
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          onTap:
                              () => _navigateToSessions(
                                context,
                                'registered_upcoming',
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Unregistered Upcoming',
                          count: counts['unregisteredUpcoming'] ?? 0,
                          icon: Icons.event_available,
                          color: Colors.orange,
                          onTap:
                              () => _navigateToSessions(
                                context,
                                'unregistered_upcoming',
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Past Sessions',
                          count: counts['past'] ?? 0,
                          icon: Icons.history,
                          color: Colors.grey,
                          onTap: () => _navigateToSessions(context, 'past'),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Registered Past',
                          count: counts['registeredPast'] ?? 0,
                          icon: Icons.assignment_turned_in,
                          color: Colors.deepPurple,
                          onTap:
                              () => _navigateToSessions(
                                context,
                                'registered_past',
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'All Registered Sessions',
                          count: counts['registeredAll'] ?? 0,
                          icon: Icons.assignment,
                          color: Colors.amber,
                          onTap:
                              () => _navigateToSessions(
                                context,
                                'registered_all',
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Attended Sessions',
                          count: counts['attended'] ?? 0,
                          icon: Icons.emoji_events,
                          color: Colors.teal,
                          onTap: () => _navigateToSessions(context, 'attended'),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Feedback Needed',
                          count: counts['feedbackNeeded'] ?? 0,
                          icon: Icons.feedback,
                          color: Colors.redAccent,
                          onTap:
                              () => _navigateToSessions(
                                context,
                                'feedback_needed',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
