import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/app_footer.dart';

class EditSessionScreen extends StatefulWidget {
  final int sessionId;

  const EditSessionScreen({required this.sessionId, super.key});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? sessionData;
  List<dynamic> trainers = [];
  Set<int> selectedTrainerIds = {};
  bool isLoading = true;

  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late TextEditingController targetAudienceController;
  late TextEditingController statusController;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController();
    timeController = TextEditingController();
    locationController = TextEditingController();
    targetAudienceController = TextEditingController();
    statusController = TextEditingController();
    _loadSessionDetails();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    targetAudienceController.dispose();
    statusController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    try {
      final session = await ApiService.getSessionById(widget.sessionId);
      final trainerList = await ApiService.getTrainers();

      // Handle date
      DateTime? sessionDate;
      if (session['date'] != null) {
        sessionDate = DateTime.tryParse(session['date']);
        if (sessionDate != null) {
          dateController.text = dateFormat.format(sessionDate);
        }
      }

      // Handle time
      if (session['time'] != null) {
        final timeStr = session['time'].toString();
        if (timeStr.contains('T')) {
          // Handle ISO format
          final dt = DateTime.tryParse(timeStr);
          if (dt != null) {
            timeController.text =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
          }
        } else if (timeStr.contains(':')) {
          // Handle HH:MM:SS format
          timeController.text = timeStr;
        }
      }

      // Handle other fields
      locationController.text = session['location']?.toString() ?? '';
      targetAudienceController.text =
          session['target_audience']?.toString() ?? '';
      statusController.text = session['status']?.toString() ?? 'Upcoming';

      // Handle trainers
      Set<int> assignedTrainerIds = {};
      if (session['trainers'] != null) {
        assignedTrainerIds =
            session['trainers'].map<int>((t) => t['id'] as int).toSet();
      }
      setState(() {
        sessionData = session;
        trainers = trainerList;
        selectedTrainerIds = assignedTrainerIds;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load session details: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now();
    if (sessionData != null && sessionData!['date'] != null) {
      final dt = DateTime.tryParse(sessionData!['date']);
      if (dt != null) initialDate = dt;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    _updateDate(picked);
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime = _getTimeFromSession() ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    _updateTime(picked);
  }

  TimeOfDay? _getTimeFromSession() {
    if (sessionData != null && sessionData!['time'] != null) {
      // Handle both 'HH:MM:SS' and full ISO format
      final timeStr = sessionData!['time'];
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 3) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final _ = int.tryParse(parts[2]) ?? 0; // seconds not used
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      final dt = DateTime.tryParse(timeStr);
      if (dt != null) return TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    return const TimeOfDay(hour: 8, minute: 0); // Default to 8:00 AM
  }

  void _updateTime(TimeOfDay time) {
    sessionData!['time'] =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    timeController.text =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _updateDate(DateTime picked) {
    final updatedDate = DateTime(picked.year, picked.month, picked.day);
    sessionData!['date'] = updatedDate.toIso8601String();
    setState(() {
      dateController.text = dateFormat.format(picked);
    });
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (sessionData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session data is missing.')));
      return;
    }

    final workshopId = sessionData!['workshop']?['id'];
    if (workshopId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workshop ID is missing.')));
      return;
    }

    try {
      // Validate date format (YYYY-MM-DD)
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(dateController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid date format. Use YYYY-MM-DD')),
        );
        return;
      }

      // Validate time format (HH:mm:ss)
      final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$');
      if (!timeRegex.hasMatch(timeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid time format. Use HH:mm:ss')),
        );
        return;
      }

      final updateSuccess = await ApiService.updateSession(widget.sessionId, {
        'workshop_id': workshopId,
        'date': dateController.text,
        'time': timeController.text,
        'location': locationController.text.trim(),
        'target_audience': targetAudienceController.text.trim(),
        'status': statusController.text.trim(),
      });

      final assignSuccess = await ApiService.assignTrainersToSession(
        widget.sessionId,
        selectedTrainerIds.toList(),
      );

      if (updateSuccess && assignSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update session.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeTrainer(int trainerId) async {
    final success = await ApiService.removeTrainerFromSession(
      widget.sessionId,
      trainerId,
    );
    if (success) {
      setState(() {
        selectedTrainerIds.remove(trainerId);
        if (sessionData != null && sessionData!['trainers'] != null) {
          sessionData!['trainers'] =
              sessionData!['trainers']
                  .where((t) => t['id'] != trainerId)
                  .toList();
        }
      });
    }
  }

  Widget _buildFormSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Session Details')),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workshop title (read-only)
                Text(
                  sessionData?['workshop']?['title'] ?? 'Unknown Workshop',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                // Date & Time pickers grouped
                _buildFormSection(
                  title: 'Date & Time',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onTap: _pickDate,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select a date'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: timeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onTap: _pickTime,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select a time'
                                      : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Location input
                _buildFormSection(
                  title: 'Location',
                  child: TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Location is required'
                                : null,
                  ),
                ),

                // Target Audience input
                _buildFormSection(
                  title: 'Target Audience',
                  child: TextFormField(
                    controller: targetAudienceController,
                    decoration: const InputDecoration(
                      labelText: 'Target Audience',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Target Audience is required'
                                : null,
                  ),
                ),

                // Status input
                _buildFormSection(
                  title: 'Status',
                  child: TextFormField(
                    controller: statusController,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Status is required'
                                : null,
                  ),
                ),

                // Trainers list with selection
                _buildFormSection(
                  title: 'Assign Trainers',
                  child: Column(
                    children:
                        trainers.map((trainer) {
                          final trainerId = trainer['id'] as int;
                          final fullName = '${trainer['name']}';
                          final isSelected = selectedTrainerIds.contains(
                            trainerId,
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(fullName),
                            trailing:
                                isSelected
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeTrainer(trainerId),
                                      tooltip: 'Remove Trainer',
                                    )
                                    : IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedTrainerIds.add(trainerId);
                                        });
                                      },
                                      tooltip: 'Add Trainer',
                                    ),
                          );
                        }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _saveSession,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
