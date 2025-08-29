import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animations/animations.dart';
import 'package:file_saver/file_saver.dart';
import 'package:frontend/utils/charts_utils.dart';
import '../../services/analytics_api_service.dart';
import '../../widgets/analytics_card.dart';
import '../../widgets/metric_card.dart';
import '../../utils/constants.dart';
import '../../utils/trainer_analytics_pdf_generator.dart';
import 'dart:async';

class TrainersAnalyticsTab extends StatefulWidget {
  const TrainersAnalyticsTab({super.key});

  @override
  _TrainersAnalyticsTabState createState() => _TrainersAnalyticsTabState();
}

class _TrainersAnalyticsTabState extends State<TrainersAnalyticsTab> {
  late Future<Map<String, dynamic>> _trainersData;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _trainersData = AnalyticsApiService.getTrainersAnalytics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Generate PDF for all trainers
  Future<void> _generatePdfReport() async {
    try {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF report...')));

      final data = await _trainersData;
      final trainers = (data['trainers'] as List<dynamic>?) ?? [];

      final pdfBytes = await TrainerAnalyticsPdfGenerator.generatePdf(
        overviewData: {
          'total_trainers': data['total_trainers'] ?? 0,
          'top_trainer': data['top_trainer'] ?? 'N/A',
        },
        trainersList: trainers,
      );

      // Save the PDF
      await FileSaver.instance.saveFile(
        name: 'trainers_analytics_${DateTime.now().millisecondsSinceEpoch}',
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  // Generate PDF for a single trainer
  Future<void> _generateTrainerPdf(Map<String, dynamic> trainer) async {
    try {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating trainer report...')),
      );

      // Get detailed trainer data
      final detail = await AnalyticsApiService.getTrainerDetailAnalytics(
        trainer['id'],
      );

      final pdfBytes = await TrainerAnalyticsPdfGenerator.generateTrainerPdf(
        trainerData: detail,
      );

      // Save the PDF
      final trainerName =
          (trainer['name'] as String?)?.replaceAll(' ', '_') ?? 'trainer';
      await FileSaver.instance.saveFile(
        name: '${trainerName}_report_${DateTime.now().millisecondsSinceEpoch}',
        bytes: pdfBytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trainer report generated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating trainer PDF: $e')),
        );
      }
    }
  }

  void _openTrainerDetail(int trainerId) async {
    final detail = await AnalyticsApiService.getTrainerDetailAnalytics(
      trainerId,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrainerDetailSheet(detail: detail),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _trainersData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading trainers data',
              style: TextStyle(color: negativeColor),
            ),
          );
        }
        final data = snapshot.data!;
        final trainers =
            (data['trainers'] as List<dynamic>?)
                ?.where(
                  (t) =>
                      (t['name']?.toLowerCase() ?? '').contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (t['email']?.toLowerCase() ?? '').contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList() ??
            [];

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
                          'Trainers Overview',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _generatePdfReport,
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Export to PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: isWide ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: isWide ? 2 : 4,
                      children: [
                        EnhancedMetricCard(
                          icon: Icons.person,
                          title: 'Total Trainers',
                          value: '${data['total_trainers'] ?? 0}',
                        ),
                        EnhancedMetricCard(
                          icon: Icons.thumb_up,
                          title: 'Top Rated Trainer',
                          value: data['top_trainer'] ?? '-',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AnalyticsCard(
                      title: 'Trainer List',
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Search by name or email',
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
                            itemCount: trainers.length,
                            itemBuilder: (context, index) {
                              final trainer = trainers[index];
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
                                          Icons.person_outline,
                                          color: primaryColor,
                                        ),
                                        title: Text(
                                          trainer['name'] ??
                                              'Trainer ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Email: ${trainer['email'] ?? '-'}\n'
                                          'Sessions: ${trainer['session_count'] ?? 0}\n'
                                          'Avg. Rating: ${trainer['avg_feedback_rating'] ?? "-"}',
                                        ),
                                        onTap:
                                            () => _openTrainerDetail(
                                              trainer['id'],
                                            ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () =>
                                                  _generateTrainerPdf(trainer),
                                          tooltip: 'Generate PDF Report',
                                          color: primaryColor,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                openBuilder:
                                    (context, _) =>
                                        TrainerDetailSheet(detail: trainer),
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
  }
}

class TrainerDetailSheet extends StatelessWidget {
  final Map<String, dynamic> detail;

  const TrainerDetailSheet({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final ratingsTrend = detail['ratings_trend'] as List<dynamic>? ?? [];
    final feedbackThemes = detail['feedback_themes'] as List<dynamic>? ?? [];

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
                  detail['name'] ?? 'Trainer Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                AnalyticsCard(
                  title: 'Trainer Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${detail['email'] ?? '-'}'),
                      Text(
                        'Sessions Conducted: ${detail['session_count'] ?? 0}',
                      ),
                      Text(
                        'Total Participants: ${detail['total_participants'] ?? 0}',
                      ),
                      Text(
                        'Avg. Feedback Rating: ${detail['avg_feedback_rating'] ?? "-"}',
                      ),
                    ],
                  ),
                ),
                if (ratingsTrend.isNotEmpty)
                  AnalyticsCard(
                    title: 'Feedback Ratings Trend',
                    child: SizedBox(
                      height: 240,
                      child: BarChart(
                        AppCharts.createVerticalBarChart(
                          barGroups: List.generate(
                            ratingsTrend.length,
                            (i) => BarChartGroups.createBarGroup(
                              x: i,
                              y:
                                  (ratingsTrend[i]['avg_rating'] as num?)
                                      ?.toDouble() ??
                                  0,
                              color: Colors.amber,
                            ),
                          ),
                          maxY:
                              ratingsTrend
                                  .map(
                                    (t) =>
                                        (t['avg_rating'] as num?)?.toDouble() ??
                                        0,
                                  )
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                          bottomTitles:
                              ratingsTrend
                                  .map(
                                    (t) => t['session_title']?.toString() ?? '',
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                if (ratingsTrend.isNotEmpty)
                  AnalyticsCard(
                    title: 'Ratings Trend Details',
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ratingsTrend.length,
                      itemBuilder: (context, idx) {
                        final t = ratingsTrend[idx];
                        return ListTile(
                          title: Text(
                            t['session_title'] ?? 'Session ${idx + 1}',
                          ),
                          subtitle: Text(
                            'Date: ${t['date_time'] ?? '-'}\nAvg. Rating: ${t['avg_rating'] ?? "-"}',
                          ),
                        );
                      },
                    ),
                  ),
                if (feedbackThemes.isNotEmpty)
                  AnalyticsCard(
                    title: 'Feedback Themes',
                    child: Column(
                      children:
                          feedbackThemes
                              .map(
                                (theme) => Padding(
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
                                      Expanded(child: Text(theme)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
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
