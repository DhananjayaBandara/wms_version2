import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/charts_utils.dart';
import '../../widgets/analytics_funnel.dart';
import '../../widgets/analytics_card.dart';
import '../../utils/constants.dart';
import '../../utils/session_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class SessionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> detail;

  const SessionDetailSheet({super.key, required this.detail});

  Color _getRatingColor(int rating) {
    if (rating >= 8) return positiveColor;
    if (rating >= 5) return Colors.amber;
    return negativeColor;
  }

  @override
  Widget build(BuildContext context) {
    final ratingDist = detail['feedback_rating_distribution'] as Map? ?? {};
    final registered = (detail['registered_count'] ?? 0) as int;
    final attended = (detail['attended_count'] ?? 0) as int;
    final feedbackParticipants =
        detail['feedback_participants'] is int
            ? detail['feedback_participants'] as int
            : (detail['feedback_participants'] is List
                ? (detail['feedback_participants'] as List).length
                : 0);
    final absent = registered - attended;
    final attendedPercent =
        registered > 0 ? (attended / registered * 100).round() : 0;
    final absentPercent =
        registered > 0 ? (absent / registered * 100).round() : 0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    Icon(Icons.analytics, color: primaryColor, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail['title'] ?? 'Session Details',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: primaryColor,
                      ),
                      tooltip: 'Generate PDF',
                      onPressed: () async {
                        final pdfData = await SessionPdfGenerator.generatePdf(
                          detail,
                        );
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) => pdfData,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AnalyticsCard(
                  title: 'Session Information',
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: Colors.blue.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 6),

                          Text(detail['workshop'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.green.shade300,
                            size: 18,
                          ),
                          const SizedBox(width: 6),

                          Text(detail['date'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.orange.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(detail['time'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              detail['location'] ?? 'Online',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            color: Colors.orange.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Registered: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('$registered'),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Attended: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('$attended'),
                        ],
                      ),
                    ],
                  ),
                ),
                AnalyticsCard(
                  title: 'Session Funnel',
                  padding: const EdgeInsets.all(14),
                  child: AnalyticsFunnel(
                    registered: registered,
                    attended: attended,
                    feedbackCount: feedbackParticipants,
                    compact: true,
                  ),
                ),
                AnalyticsCard(
                  title: 'Attendance Distribution',
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              AppCharts.createPieChart(
                                sections: AppCharts.createPieSections(
                                  values: [
                                    registered > 0
                                        ? (attended.toDouble() / registered) *
                                            100
                                        : 0,
                                    registered > 0
                                        ? (absent.toDouble() / registered) * 100
                                        : 0,
                                  ],
                                  colors: [positiveColor, negativeColor],
                                  titles: [
                                    '$attendedPercent%',
                                    '$absentPercent%',
                                  ],
                                  radius: 60,
                                ),
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCharts.buildPieChartLegend(
                        colors: [positiveColor, negativeColor],
                        labels: ['Attended', 'Absent'],
                        values: ['$attendedPercent%', '$absentPercent%'],
                      ),
                    ],
                  ),
                ),
                AnalyticsCard(
                  title: 'Feedback Rating Distribution',
                  padding: const EdgeInsets.all(14),
                  child:
                      ratingDist.isEmpty
                          ? const Text('No feedback ratings available.')
                          : SizedBox(
                            height: 200,
                            child: BarChart(
                              AppCharts.createVerticalBarChart(
                                barGroups: List.generate(10, (index) {
                                  final rating = index + 1;
                                  return BarChartGroups.createBarGroup(
                                    x: rating - 1,
                                    y:
                                        (ratingDist[rating.toString()] ?? 0)
                                            .toDouble(),
                                    color: _getRatingColor(rating),
                                  );
                                }),
                                maxY:
                                    (ratingDist.values.isNotEmpty
                                        ? (ratingDist.values.reduce(
                                                  (a, b) => a > b ? a : b,
                                                )
                                                as num)
                                            .toDouble()
                                        : 1.0) *
                                    1.2,
                                bottomTitles: List.generate(
                                  10,
                                  (i) => '${i + 1}',
                                ),
                              ),
                            ),
                          ),
                ),
                if ((detail['feedback_suggestions'] as List?)?.isNotEmpty ??
                    false)
                  AnalyticsCard(
                    title: 'Top Suggestions/Problems',
                    padding: const EdgeInsets.all(14),
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
                  title: 'Participants',
                  padding: const EdgeInsets.all(14),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (detail['participants'] as List?)?.length ?? 0,
                    itemBuilder: (context, idx) {
                      final p = detail['participants'][idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Text(
                            idx + 1 < 10 ? '0${idx + 1}' : '${idx + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(p['name'] ?? 'Unknown Participant'),
                        subtitle: Text(p['email'] ?? 'No email provided'),
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
