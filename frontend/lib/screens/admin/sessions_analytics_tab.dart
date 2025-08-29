import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/analytics_api_service.dart';
import '../../utils/charts_utils.dart';
import '../../utils/sessions_analytics_pdf_generator.dart';
import '../../widgets/analytics_funnel.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/analytics_card.dart';
import 'sessions_details_analytics_sheet.dart';
import '../../utils/constants.dart';
import 'dart:async';

class SessionsAnalyticsTab extends StatefulWidget {
  const SessionsAnalyticsTab({super.key});

  @override
  _SessionsAnalyticsTabState createState() => _SessionsAnalyticsTabState();
}

class _SessionsAnalyticsTabState extends State<SessionsAnalyticsTab> {
  late Future<Map<String, dynamic>> _overviewFuture;
  late Future<List<dynamic>> _sessionsListFuture;
  String _searchQuery = '';
  Timer? _debounce;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _overviewFuture = AnalyticsApiService.getSessionsOverview();
    _sessionsListFuture = AnalyticsApiService.getSessionsList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _openSessionDetail(int sessionId) async {
    final detail = await AnalyticsApiService.getSessionDetail(sessionId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SessionDetailSheet(detail: detail),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);
    });
  }

  // Generate PDF report
  Future<void> _generatePdfReport() async {
    if (_isGeneratingPdf) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Show loading indicator in the FAB

      // Get the latest data
      final overview = await AnalyticsApiService.getSessionsOverview();
      final sessions = await AnalyticsApiService.getSessionsList();

      // Generate PDF
      final pdfBytes = await SessionsAnalyticsPdfGenerator.generatePdf(
        overviewData: overview,
        sessionsList: sessions,
      );

      // Save the PDF to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/sessions_analytics_report.pdf');
      await file.writeAsBytes(pdfBytes);

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show options to open or share the PDF
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Report Generated'),
                content: const Text(
                  'What would you like to do with the report?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Share.shareXFiles([
                        XFile(file.path),
                      ], text: 'Sessions Analytics Report');
                    },
                    child: const Text('Share'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      OpenFile.open(file.path);
                    },
                    child: const Text('Open'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          _isGeneratingPdf
              ? FloatingActionButton(
                onPressed: null,
                backgroundColor: primaryColor,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
              : FloatingActionButton.extended(
                onPressed: _generatePdfReport,
                backgroundColor: primaryColor,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Report'),
                tooltip: 'Generate PDF Report',
              ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _overviewFuture,
        builder: (context, overviewSnapshot) {
          if (overviewSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (overviewSnapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading sessions overview',
                style: TextStyle(color: negativeColor),
              ),
            );
          }
          final overview = overviewSnapshot.data!;
          final int totalRegistered = overview['total_registered'] ?? 0;
          final int totalAttended = overview['total_attended'] ?? 0;
          final int feedbackCount = overview['feedback_count'] ?? 0;

          return FutureBuilder<List<dynamic>>(
            future: _sessionsListFuture,
            builder: (context, listSnapshot) {
              if (listSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (listSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading sessions list',
                    style: TextStyle(color: negativeColor),
                  ),
                );
              }
              final sessions = listSnapshot.data!;
              final filteredSessions =
                  _searchQuery.isEmpty
                      ? sessions
                      : sessions
                          .where(
                            (s) =>
                                (s['title']?.toLowerCase() ?? '').contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                (s['workshop']?.toLowerCase() ?? '').contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                (s['location']?.toLowerCase() ?? '').contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sessions Overview',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Metrics Grid
                          GridView.count(
                            crossAxisCount: isWide ? 3 : 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: isWide ? 2 : 4,
                            children: [
                              EnhancedMetricCard(
                                icon: Icons.event_note,
                                title: 'Total Sessions',
                                value: '${overview['total_sessions']}',
                              ),
                              EnhancedMetricCard(
                                icon: Icons.group,
                                title: 'Total Registered',
                                value: '$totalRegistered',
                              ),
                              EnhancedMetricCard(
                                icon: Icons.check_circle,
                                title: 'Total Attended',
                                value: '$totalAttended',
                                color: positiveColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Session Funnel
                          AnalyticsFunnel(
                            registered: totalRegistered,
                            attended: totalAttended,
                            feedbackCount: feedbackCount,
                            title: 'Session Funnel',
                          ),
                          const SizedBox(height: 16),
                          // Attendance Comparison
                          AnalyticsCard(
                            title: 'Attendance Rate',
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Registered vs. Attended'),
                                    Text(
                                      '${overview['average_attendance_rate']}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 240,
                                  child: BarChart(
                                    AppCharts.createVerticalBarChart(
                                      barGroups: [
                                        BarChartGroups.createBarGroup(
                                          x: 0,
                                          y: totalRegistered.toDouble(),
                                          color: primaryColor,
                                        ),
                                        BarChartGroups.createBarGroup(
                                          x: 1,
                                          y: totalAttended.toDouble(),
                                          color: positiveColor,
                                        ),
                                      ],
                                      maxY:
                                          (totalRegistered > totalAttended
                                                  ? totalRegistered
                                                  : totalAttended)
                                              .toDouble() *
                                          1.2,
                                      bottomTitles: ['Registered', 'Attended'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Attendance per Session
                          AnalyticsCard(
                            title: 'Attendance per Session',
                            child: _buildAttendancePerSessionChart(overview),
                          ),
                          const SizedBox(height: 16),
                          // Sessions List
                          AnalyticsCard(
                            title: 'Sessions List',
                            child: Column(
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Search by title or workshop',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        _searchQuery.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed:
                                                  () => setState(
                                                    () => _searchQuery = '',
                                                  ),
                                            )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  onChanged: _onSearchChanged,
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredSessions.length,
                                  itemBuilder: (context, index) {
                                    final session = filteredSessions[index];
                                    return OpenContainer(
                                      transitionType:
                                          ContainerTransitionType.fadeThrough,
                                      closedElevation: 0,
                                      closedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      closedBuilder:
                                          (context, openContainer) => Card(
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.event,
                                                color: primaryColor,
                                              ),
                                              title: Text(
                                                session['title'] ??
                                                    'Session ${index + 1}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              subtitle: Text(
                                                'Location: ${session['location'] ?? '-'}\n'
                                                'Registered: ${session['registered_count'] ?? 0} | '
                                                'Attended: ${session['attended_count'] ?? 0} | '
                                                'Avg. Rating: ${session['avg_feedback_rating'] ?? "-"}',
                                              ),
                                              onTap:
                                                  () => _openSessionDetail(
                                                    session['id'],
                                                  ),
                                            ),
                                          ),
                                      openBuilder:
                                          (context, _) => SessionDetailSheet(
                                            detail: session,
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendancePerSessionChart(Map<String, dynamic> overview) {
    final sessionTitles = (overview['session_titles'] as List<dynamic>?) ?? [];
    final attendancePerSession =
        (overview['attendance_per_session'] as List<dynamic>?) ?? [];

    if (sessionTitles.isEmpty || attendancePerSession.isEmpty) {
      return const Text('No session attendance data.');
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        AppCharts.createVerticalBarChart(
          barGroups: List.generate(
            sessionTitles.length,
            (i) => BarChartGroups.createBarGroup(
              x: i,
              y: (attendancePerSession[i] as num).toDouble(),
              color: positiveColor,
            ),
          ),
          maxY:
              (attendancePerSession.reduce((a, b) => a > b ? a : b) as num)
                  .toDouble() *
              1.2,
          bottomTitles: sessionTitles.map((t) => t.toString()).toList(),
        ),
      ),
    );
  }
}
