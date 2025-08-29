import 'package:animations/animations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:frontend/screens/admin/sessions_details_analytics_sheet.dart';
import 'package:frontend/utils/charts_utils.dart';
import 'package:frontend/widgets/analytics_card.dart';
import 'package:frontend/widgets/analytics_funnel.dart';
import 'package:frontend/widgets/metric_card.dart';
import '../../services/analytics_api_service.dart';
import '../../utils/constants.dart';
import '../../utils/workshop_analytics_pdf_generator.dart';
import 'dart:async';

class WorkshopsAnalyticsTab extends StatefulWidget {
  const WorkshopsAnalyticsTab({super.key});

  @override
  _WorkshopsAnalyticsTabState createState() => _WorkshopsAnalyticsTabState();
}

class _WorkshopsAnalyticsTabState extends State<WorkshopsAnalyticsTab> {
  late Future<Map<String, dynamic>> _overviewFuture;
  late Future<List<dynamic>> _workshopsListFuture;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _overviewFuture = AnalyticsApiService.getWorkshopsOverview();
    _workshopsListFuture = AnalyticsApiService.getWorkshopsList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _openWorkshopDetail(int workshopId) async {
    final detail = await AnalyticsApiService.getWorkshopDetail(workshopId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WorkshopDetailSheet(detail: detail),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);
    });
  }

  Future<void> _generatePdf() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Get the latest data
      final overview = await _overviewFuture;
      final workshopsList = await _workshopsListFuture;

      // Generate PDF
      final pdfFile = await WorkshopAnalyticsPdfGenerator.generatePdf(
        overviewData: overview,
        workshopsList: workshopsList,
      );

      // Save PDF
      await FileSaver.instance.saveFile(
        name:
            'workshops_analytics_${DateTime.now().millisecondsSinceEpoch}.pdf',
        bytes: pdfFile,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _overviewFuture,
      builder: (context, overviewSnapshot) {
        if (overviewSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (overviewSnapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading workshops overview',
              style: TextStyle(color: negativeColor),
            ),
          );
        }
        final overview = overviewSnapshot.data!;
        final int totalRegistered = overview['total_registered'] ?? 0;
        final int totalAttended = overview['total_attended'] ?? 0;
        final int feedbackParticipants =
            overview['feedback_participants'] is int
                ? overview['feedback_participants'] as int
                : (overview['feedback_participants'] is List
                    ? (overview['feedback_participants'] as List).length
                    : 0);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
            tooltip: 'Generate PDF',
            backgroundColor: primaryColor,
          ),
          body: FutureBuilder<List<dynamic>>(
            future: _workshopsListFuture,
            builder: (context, listSnapshot) {
              if (listSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (listSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading workshops list',
                    style: TextStyle(color: negativeColor),
                  ),
                );
              }
              final workshops = listSnapshot.data!;
              final filteredWorkshops =
                  _searchQuery.isEmpty
                      ? workshops
                      : workshops
                          .where(
                            (w) => (w['title']?.toLowerCase() ?? '').contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();
              final workshopTitles =
                  filteredWorkshops
                      .map((w) => w['title'] as String? ?? '')
                      .toList();
              final attendeesPerWorkshop =
                  filteredWorkshops
                      .map((w) => (w['total_attended'] ?? 0) as int)
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
                          Text(
                            'Workshops Overview',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Metrics Grid
                          GridView.count(
                            crossAxisCount: isWide ? 5 : 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: isWide ? 2 : 4,
                            children: [
                              EnhancedMetricCard(
                                icon: Icons.work,
                                title: 'Total Workshops',
                                value: '${overview['total_workshops']}',
                              ),
                              EnhancedMetricCard(
                                icon: Icons.list_alt,
                                title: 'Total Sessions',
                                value: '${overview['total_sessions']}',
                              ),
                              EnhancedMetricCard(
                                icon: Icons.person_add,
                                title: 'Total Registered',
                                value: '$totalRegistered',
                              ),
                              EnhancedMetricCard(
                                icon: Icons.check_circle,
                                title: 'Total Attended',
                                value: '$totalAttended',
                                color: positiveColor,
                              ),
                              EnhancedMetricCard(
                                icon: Icons.star,
                                title: 'Avg. Feedback Rating',
                                value:
                                    '${overview['average_feedback_rating'] ?? "-"}',
                                color: Colors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Workshop Funnel
                          AnalyticsFunnel(
                            registered: totalRegistered,
                            attended: totalAttended,
                            feedbackCount: feedbackParticipants,
                            title: 'Workshop Funnel',
                          ),
                          const SizedBox(height: 16),
                          // Attendees per Workshop
                          AnalyticsCard(
                            title: 'Attendees per Workshop',
                            child: SizedBox(
                              height: 240,
                              child: BarChart(
                                AppCharts.createVerticalBarChart(
                                  barGroups: List.generate(
                                    workshopTitles.length,
                                    (i) => BarChartGroups.createBarGroup(
                                      x: i,
                                      y: attendeesPerWorkshop[i].toDouble(),
                                      color: positiveColor,
                                    ),
                                  ),
                                  maxY:
                                      attendeesPerWorkshop.isNotEmpty
                                          ? attendeesPerWorkshop
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  )
                                                  .toDouble() *
                                              1.2
                                          : 10,
                                  bottomTitles: workshopTitles,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Workshops List
                          AnalyticsCard(
                            title: 'Workshops List',
                            child: Column(
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Search by workshop title',
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
                                  itemCount: filteredWorkshops.length,
                                  itemBuilder: (context, index) {
                                    final workshop = filteredWorkshops[index];
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
                                                Icons.work,
                                                color: primaryColor,
                                              ),
                                              title: Text(
                                                workshop['title']
                                                        .toUpperCase() ??
                                                    'Workshop ${index + 1}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Sessions: ${workshop['total_sessions'] ?? 0}\n'
                                                'Registered: ${workshop['total_registered'] ?? 0}\n'
                                                'Attended: ${workshop['total_attended'] ?? 0}\n'
                                                'Avg. Rating: ${workshop['avg_feedback_rating'] ?? "-"}',
                                              ),
                                              onTap:
                                                  () => _openWorkshopDetail(
                                                    workshop['id'],
                                                  ),
                                            ),
                                          ),
                                      openBuilder:
                                          (context, _) => WorkshopDetailSheet(
                                            detail: workshop,
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
          ),
        );
      },
    );
  }
}

class WorkshopDetailSheet extends StatelessWidget {
  final Map<String, dynamic> detail;

  const WorkshopDetailSheet({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final trend = detail['trend'] as List<dynamic>? ?? [];
    final int reg = detail['total_registered'] ?? 0;
    final int att = detail['total_attended'] ?? 0;
    final int feedbackParticipants =
        detail['feedback_participants'] is int
            ? detail['feedback_participants'] as int
            : (detail['feedback_participants'] is List
                ? (detail['feedback_participants'] as List).length
                : 0);
    final int absent = reg - att;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  detail['title'] ?? 'Workshop Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                AnalyticsCard(
                  title: 'Workshop Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sessions: ${detail['total_sessions'] ?? 0}'),
                      Text('Registered: $reg'),
                      Text('Attended: $att'),
                      Text(
                        'Avg. Feedback Rating: ${detail['avg_feedback_rating'] ?? "-"}',
                      ),
                    ],
                  ),
                ),
                AnalyticsCard(
                  title: 'Workshop Funnel',
                  child: AnalyticsFunnel(
                    registered: reg,
                    attended: att,
                    feedbackCount: feedbackParticipants,
                    compact: true,
                  ),
                ),
                AnalyticsCard(
                  title: 'Attendance Distribution',
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      AppCharts.createPieChart(
                        sections: AppCharts.createPieSections(
                          values: [
                            reg > 0 ? (att.toDouble() / reg) * 100 : 0,
                            reg > 0 ? (absent.toDouble() / reg) * 100 : 0,
                          ],
                          colors: [positiveColor, negativeColor],
                          titles: [
                            'Attended: ${(reg > 0 ? (att.toDouble() / reg * 100) : 0).toStringAsFixed(2)}%',
                            'Absent: ${(reg > 0 ? (absent.toDouble() / reg * 100) : 0).toStringAsFixed(2)}%',
                          ],
                          radius: 50,
                        ),
                      ),
                    ),
                  ),
                ),
                if ((detail['feedback_suggestions'] as List?)?.isNotEmpty ??
                    false)
                  AnalyticsCard(
                    title: 'Top Suggestions/Issues',
                    child: Column(
                      children:
                          (detail['feedback_suggestions'] as List)
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: 4.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Expanded(child: Text(s)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                AnalyticsCard(
                  title: 'Top Keywords',
                  child: Text(
                    detail['top_keywords']?.join(", ") ??
                        'No keywords available',
                  ),
                ),
                if (trend.isNotEmpty)
                  AnalyticsCard(
                    title: 'Session Trends',
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trend.length,
                      itemBuilder: (context, idx) {
                        final t = trend[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 0,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.timeline,
                              color: Colors.blue,
                            ),
                            title: Text(t['title'] ?? 'Session ${idx + 1}'),
                            subtitle: Text(
                              'Date: ${t['date_time'] ?? '-'}\n'
                              'Registered: ${t['registered'] ?? 0}\n'
                              'Attended: ${t['attended'] ?? 0}\n'
                              'Avg. Rating: ${t['avg_rating'] ?? "-"}',
                            ),
                            onTap: () async {
                              // Fetch session detail and show SessionDetailSheet
                              final detail =
                                  await AnalyticsApiService.getSessionDetail(
                                    t['session_id'],
                                  );
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder:
                                    (_) => SessionDetailSheet(detail: detail),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
