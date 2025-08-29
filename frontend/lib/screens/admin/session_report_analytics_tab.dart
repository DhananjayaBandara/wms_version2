import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/analytics_api_service.dart';
import 'sessions_details_analytics_sheet.dart';
import '../../widgets/analytics_funnel.dart';
import '../../widgets/analytics_card.dart';
import '../../utils/constants.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import '../../utils/session_report_pdf_generator.dart';

class SessionsReportAnalyticsTab extends StatefulWidget {
  const SessionsReportAnalyticsTab({Key? key}) : super(key: key);

  @override
  State<SessionsReportAnalyticsTab> createState() =>
      _SessionsReportAnalyticsTabState();
}

class _SessionsReportAnalyticsTabState
    extends State<SessionsReportAnalyticsTab> {
  String _selectedPeriod = 'annual';
  DateTimeRange? _customRange;
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() {
    setState(() {
      _reportFuture = ApiService.getSessionsReportOverview(
        period: _selectedPeriod,
        dateFrom:
            _customRange?.start != null
                ? DateFormat('yyyy-MM-dd').format(_customRange!.start)
                : null,
        dateTo:
            _customRange?.end != null
                ? DateFormat('yyyy-MM-dd').format(_customRange!.end)
                : null,
      );
    });
  }

  void _openSessionDetail(int sessionId) async {
    final detail = await AnalyticsApiService.getSessionDetail(sessionId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SessionDetailSheet(detail: detail),
    );
  }

  void _showSessionsList(List sessionIds) async {
    if (sessionIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No sessions available')));
      return;
    }
    final sessions = await ApiService.getSessionsByIds(sessionIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            builder:
                (context, scrollController) => ListView.builder(
                  controller: scrollController,
                  itemCount: sessions.length,
                  itemBuilder: (context, idx) {
                    final session = sessions[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.blue),
                        title: Text(
                          '${session['workshop']['title'] ?? 'Session ${idx + 1}'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date: ${session['date'] ?? '-'}\n'
                          'Location: ${session['location'] ?? 'Online'}',
                        ),
                        onTap: () => _openSessionDetail(session['id']),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  void _showParticipantsList(
    List participants, {
    String title = 'Participants',
    List attendedIds = const [],
    List feedbackIds = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: participants.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final p = participants[idx];
                          final pid = p['id'];
                          final hasAttended = attendedIds.contains(pid);
                          final hasFeedback = feedbackIds.contains(pid);
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text('${idx + 1}'),
                              ),
                              title: Text(
                                p['name'] ?? p['nic'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['email'] ?? p['nic'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        hasAttended
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color:
                                            hasAttended
                                                ? Colors.green
                                                : Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasAttended
                                            ? 'Attended'
                                            : 'Not Attended',
                                        style: TextStyle(
                                          color:
                                              hasAttended
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        hasFeedback
                                            ? Icons.feedback
                                            : Icons.feedback_outlined,
                                        color:
                                            hasFeedback
                                                ? Colors.amber
                                                : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasFeedback
                                            ? 'Feedback'
                                            : 'No Feedback',
                                        style: TextStyle(
                                          color:
                                              hasFeedback
                                                  ? Colors.amber[800]
                                                  : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = 'custom';
      });
      _fetchReport();
    }
  }

  Future<void> _generatePdf() async {
    final reportData = await _reportFuture;
    final pdfBytes = await SessionReportPdfGenerator.generatePdf(reportData);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    final Directory? downloadsDir = await getDownloadsDirectory();
    final String defaultPath = downloadsDir?.path ?? '';
    String savePath = path.join(defaultPath, 'session_report.pdf');
    final file = File(savePath);
    await file.writeAsBytes(pdfBytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: _selectedPeriod == 'daily',
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod = 'daily';
                      _customRange = null;
                    });
                    _fetchReport();
                  },
                ),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: _selectedPeriod == 'weekly',
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod = 'weekly';
                      _customRange = null;
                    });
                    _fetchReport();
                  },
                ),
                ChoiceChip(
                  label: const Text('Monthly'),
                  selected: _selectedPeriod == 'monthly',
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod = 'monthly';
                      _customRange = null;
                    });
                    _fetchReport();
                  },
                ),
                ChoiceChip(
                  label: const Text('Annual'),
                  selected: _selectedPeriod == 'annual',
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod = 'annual';
                      _customRange = null;
                    });
                    _fetchReport();
                  },
                ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _selectedPeriod == 'custom',
                  onSelected: (_) => _pickCustomRange(),
                ),
                if (_selectedPeriod == 'custom' && _customRange != null)
                  Text(
                    '${DateFormat('yyyy-MM-dd').format(_customRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_customRange!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading report: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final data = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessions Report Overview',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatPeriod(data['date_from'], data['date_to']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _MetricTile(
                            'Total Sessions',
                            data['total_sessions'],
                            onTap: () {
                              final sessionIds = data['session_ids'] ?? [];
                              _showSessionsList(sessionIds);
                            },
                          ),
                          _MetricTile(
                            'Registered',
                            data['total_registered'],
                            onTap: () async {
                              final ids =
                                  data['registered_participant_ids'] ?? [];
                              if (ids.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No registered participants'),
                                  ),
                                );
                                return;
                              }
                              final participants =
                                  await ApiService.getParticipantsByIds(ids);
                              _showParticipantsList(
                                participants,
                                title: 'Registered Participants',
                                attendedIds:
                                    data['attended_participant_ids'] ?? [],
                                feedbackIds:
                                    data['feedback_participant_ids'] ?? [],
                              );
                            },
                          ),
                          _MetricTile(
                            'Attended',
                            data['total_attended'],
                            onTap: () async {
                              final ids =
                                  data['attended_participant_ids'] ?? [];
                              if (ids.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No attended participants'),
                                  ),
                                );
                                return;
                              }
                              final participants =
                                  await ApiService.getParticipantsByIds(ids);
                              _showParticipantsList(
                                participants,
                                title: 'Attended Participants',
                                attendedIds:
                                    data['attended_participant_ids'] ?? [],
                                feedbackIds:
                                    data['feedback_participant_ids'] ?? [],
                              );
                            },
                          ),
                          _MetricTile(
                            'Feedback',
                            data['feedback_count'],
                            onTap: () async {
                              final ids =
                                  data['feedback_participant_ids'] ?? [];
                              if (ids.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No feedback submitted participants',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final participants =
                                  await ApiService.getParticipantsByIds(ids);
                              _showParticipantsList(
                                participants,
                                title: 'Feedback Submitted Participants',
                                attendedIds:
                                    data['attended_participant_ids'] ?? [],
                                feedbackIds:
                                    data['feedback_participant_ids'] ?? [],
                              );
                            },
                          ),
                          _MetricTile(
                            'Avg. Feedback Rating',
                            data['average_feedback_rating'] ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnalyticsFunnel(
                        registered: data['funnel']['registered'] ?? 0,
                        attended: data['funnel']['attended'] ?? 0,
                        feedbackCount:
                            data['funnel']['feedback_submitted'] ?? 0,
                        title: 'Session Funnel',
                      ),
                      const SizedBox(height: 16),
                      if (data['daily_breakdown'] != null &&
                          data['daily_breakdown'].isNotEmpty)
                        AnalyticsCard(
                          title: 'Daily Breakdown',
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      200, // Maximum width of each card
                                  childAspectRatio:
                                      2 / 3, // Rectangular aspect ratio
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount:
                                (data['daily_breakdown']
                                        as Map<String, dynamic>)
                                    .length,
                            itemBuilder: (context, idx) {
                              final entry = (data['daily_breakdown']
                                      as Map<String, dynamic>)
                                  .entries
                                  .elementAt(idx);
                              final date = entry.key;
                              final metrics = entry.value;
                              return ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 200),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),

                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                date,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                              ),
                                              Icon(
                                                Icons.calendar_month_outlined,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          _MetricChip(
                                            icon: Icons.event,
                                            label: 'Sessions',
                                            value: '${metrics['sessions']}',
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(height: 8),
                                          _MetricChip(
                                            icon: Icons.person_add,
                                            label: 'Registered',
                                            value: '${metrics['registered']}',
                                            color: Colors.green,
                                          ),
                                          const SizedBox(height: 8),
                                          _MetricChip(
                                            icon: Icons.check_circle,
                                            label: 'Attended',
                                            value: '${metrics['attended']}',
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(height: 8),
                                          _MetricChip(
                                            icon: Icons.feedback,
                                            label: 'Feedback',
                                            value: '${metrics['feedback']}',
                                            color: Colors.orange,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePdf,
        tooltip: 'Generate PDF Report',
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }

  String _formatPeriod(dynamic from, dynamic to) {
    DateTime? start;
    DateTime? end;
    if (from is String) start = DateTime.tryParse(from);
    if (to is String) end = DateTime.tryParse(to);
    if (from is DateTime) start = from;
    if (to is DateTime) end = to;
    if (start == null || end == null) return '';
    final df = DateFormat('dd.MM.yyyy');
    if (start == end) {
      return 'For: ${df.format(start)}';
    }
    return 'From: ${df.format(start)} To: ${df.format(end)}';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final dynamic value;
  final VoidCallback? onTap;
  const _MetricTile(this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              onTap != null ? Colors.blue.shade50 : Colors.grey[100],
          side: BorderSide(
            color: onTap != null ? Colors.blue : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: onTap,
        child: Text(
          '$label: $value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: onTap != null ? Colors.blue.shade900 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
