import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class WorkshopAnalyticsPdfGenerator {
  // Define colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1A73E8);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF34A853);
  static const PdfColor accentColor = PdfColor.fromInt(0xFFFBBC05);
  static const PdfColor grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor grey800 = PdfColor.fromInt(0xFF424242);

  // Helper method to safely get int values from map
  static int _safeGetInt(Map<String, dynamic> map, String key) {
    if (map[key] == null) return 0;
    if (map[key] is int) return map[key];
    return int.tryParse(map[key].toString()) ?? 0;
  }

  // Main method to generate PDF
  static Future<Uint8List> generatePdf({
    required Map<String, dynamic> overviewData,
    required List<dynamic> workshopsList,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (pw.Context context) => [
              _buildHeader(dateFormat.format(now), timeFormat.format(now)),
              pw.SizedBox(height: 20),
              _buildSectionTitle('Workshops Overview'),
              pw.SizedBox(height: 16),
              _buildOverviewCards(overviewData),
              pw.SizedBox(height: 24),
              _buildSectionTitle('Workshop Funnel'),
              pw.SizedBox(height: 12),
              _buildWorkshopFunnel(overviewData),
              pw.SizedBox(height: 24),
              _buildSectionTitle('Attendance Per Workshop'),
              pw.SizedBox(height: 12),
              _buildAttendancePerWorkshopChart(workshopsList),
              pw.SizedBox(height: 24),
              _buildSectionTitle('Workshops List'),
              pw.SizedBox(height: 12),
              _buildWorkshopsList(workshopsList),
            ],
      ),
    );

    return pdf.save();
  }

  static Future<pw.Font> _loadFont() async {
    // Load a default font (handled by the pdf package)
    return pw.Font.helvetica();
  }

  static pw.Widget _buildHeader(String date, String time) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Workshops Analytics Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.Text(
              'Generated on $date at $time',
              style: const pw.TextStyle(fontSize: 10, color: grey600),
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: grey200),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildOverviewCards(Map<String, dynamic> overview) {
    final totalWorkshops = _safeGetInt(overview, 'total_workshops');
    final totalSessions = _safeGetInt(overview, 'total_sessions');
    final totalRegistered = _safeGetInt(overview, 'total_registered');
    final totalAttended = _safeGetInt(overview, 'total_attended');
    final attendanceRate =
        totalRegistered > 0
            ? (totalAttended / totalRegistered * 100).toStringAsFixed(1)
            : '0.0';

    return pw.Row(
      children: [
        _buildMetricCard(
          'Total Workshops',
          totalWorkshops.toString(),
          PdfIcons.work,
          0.24,
        ),
        pw.SizedBox(width: 12),
        _buildMetricCard(
          'Total Sessions',
          totalSessions.toString(),
          PdfIcons.event,
          0.24,
        ),
        pw.SizedBox(width: 12),
        _buildMetricCard(
          'Total Registered',
          totalRegistered.toString(),
          PdfIcons.people,
          0.24,
        ),
        pw.SizedBox(width: 12),
        _buildMetricCard(
          'Attendance Rate',
          '$attendanceRate%',
          PdfIcons.percent,
          0.24,
        ),
        pw.SizedBox(width: 12),
        _buildMetricCard(
          'Average Feedback Rating',
          overview['average_feedback_rating']?.toString() ?? 'N/A',
          PdfIcons.star,
          0.30,
        ),
      ],
    );
  }

  static pw.Widget _buildMetricCard(
    String title,
    String value,
    int icon,
    double widthFactor,
  ) {
    return pw.Expanded(
      flex: (widthFactor * 100).toInt(),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4)],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.SizedBox(width: 8),
                pw.Text(
                  title,
                  style: pw.TextStyle(color: grey600, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: grey800,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildWorkshopFunnel(Map<String, dynamic> overview) {
    final int totalWorkshops = _safeGetInt(overview, 'total_workshops');
    final int totalSessions = _safeGetInt(overview, 'total_sessions');
    final int totalRegistered = _safeGetInt(overview, 'total_registered');
    final int totalAttended = _safeGetInt(overview, 'total_attended');
    final int totalFeedbackSubmitted = _safeGetInt(
      overview,
      'feedback_participants',
    );
    // Calculate max value for scaling
    final int maxValue = [
      totalWorkshops,
      totalSessions,
      totalRegistered,
      totalAttended,
      totalFeedbackSubmitted,
    ].reduce((a, b) => a > b ? a : b);
    final double maxValueD = maxValue.toDouble();

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildFunnelBar(
                'Registered',
                totalRegistered,
                maxValueD,
                accentColor,
              ),
              _buildFunnelBar(
                'Attended',
                totalAttended,
                maxValueD,
                PdfColor.fromInt(0xFF34A853), // Green color for attended
              ),
              _buildFunnelBar(
                'Feedback',
                totalFeedbackSubmitted,
                maxValueD,
                PdfColor.fromInt(0xFFFFA000), // Orange color for feedback
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Shows the progression from registrations to attendance to feedback',
            style: pw.TextStyle(
              fontSize: 8,
              color: grey600,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFunnelBar(
    String label,
    int value,
    double maxValue,
    PdfColor color,
  ) {
    const double maxBarHeight = 150.0;
    final double barHeight =
        maxValue > 0 ? (value / maxValue) * maxBarHeight : 0;
    const double barWidth = 40.0;
    final bool showValue = value > 0;

    return pw.Container(
      width: barWidth + 20,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (showValue)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                value.toString(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            )
          else
            pw.SizedBox(height: 20),

          pw.SizedBox(height: 4),

          // Bar container with dynamic height
          pw.Stack(
            alignment: pw.Alignment.bottomCenter,
            children: [
              // Background container (full height)
              pw.Container(
                width: barWidth,
                height: maxBarHeight,
                decoration: pw.BoxDecoration(
                  color: grey200,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
              ),
              // Actual bar (height based on value)
              if (showValue)
                pw.Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(4),
                      topRight: pw.Radius.circular(4),
                    ),
                  ),
                ),
            ],
          ),

          pw.SizedBox(height: 8),

          // Label with conversion rate if applicable
          pw.Container(
            width: barWidth + 20,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Main label
                pw.Text(
                  label,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: grey800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAttendancePerWorkshopChart(List<dynamic> workshops) {
    if (workshops.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No workshop data available',
          style: pw.TextStyle(fontSize: 12, color: grey600),
        ),
      );
    }

    // Sort workshops by attendance (descending)
    final sortedWorkshops = List<dynamic>.from(workshops)
      ..sort((a, b) => (b['total_attended'] ?? 0).compareTo(a['total_attended'] ?? 0));

    // Use all workshops
    final maxAttendance = sortedWorkshops.isNotEmpty
        ? sortedWorkshops
            .map((w) => _safeGetInt(w, 'total_attended'))
            .reduce((a, b) => a > b ? a : b)
        : 0;

    // Calculate dynamic height based on number of workshops (25px per workshop + 30px for title)
    final double chartHeight = (sortedWorkshops.length * 25.0) + 30.0;
    
    return pw.Container(
      height: chartHeight.clamp(100.0, 500.0), // Min 100px, Max 500px
      child: pw.Column(
        children: [
          pw.Expanded(
            child: pw.ListView.builder(
              itemCount: sortedWorkshops.length,
              itemBuilder: (context, index) {
                final workshop = sortedWorkshops[index];
                final title =
                    workshop['title']?.toString() ?? 'Untitled Workshop';
                final attended = _safeGetInt(workshop, 'total_attended');
                final registered = _safeGetInt(workshop, 'total_registered');
                final attendanceRate =
                    registered > 0 ? (attended / registered * 100).toInt() : 0;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 120,
                            child: pw.Text(
                              title.length > 20
                                  ? '${title.substring(0, 30)}...'
                                  : title,
                              style: const pw.TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Stack(
                              children: [
                                // Background bar
                                pw.Container(
                                  height: 20,
                                  decoration: pw.BoxDecoration(
                                    color: grey200,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                ),
                                // Filled bar
                                if (maxAttendance > 0)
                                  pw.Container(
                                    width: (attended / maxAttendance) * 200,
                                    height: 20,
                                    decoration: pw.BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                  ),
                                // Text overlay
                                pw.Positioned.fill(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          '$attended attended',
                                          style: pw.TextStyle(
                                            color: grey800,
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Text(
                                          '$attendanceRate%',
                                          style: pw.TextStyle(
                                            color: grey800,
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          pw.Text(
            'Workshops by Attendance (${sortedWorkshops.length} total)',
            style: pw.TextStyle(
              fontSize: 8,
              color: grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWorkshopsList(List<dynamic> workshops) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.TableHelper.fromTextArray(
          context: null,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Title
            1: const pw.FlexColumnWidth(1), // Sessions
            2: const pw.FlexColumnWidth(1.2), // Registered
            3: const pw.FlexColumnWidth(1.2), // Attended
            4: const pw.FlexColumnWidth(1), // Rating
          },
          data: [
            ['Workshop', 'Sessions', 'Registered', 'Attended', 'Avg. Rating'],
            ...workshops.map((workshop) {
              final registered = _safeGetInt(workshop, 'total_registered');
              final attended = _safeGetInt(workshop, 'total_attended');
              final rating =
                  workshop['avg_feedback_rating']?.toStringAsFixed(1) ?? '-';

              return [
                workshop['title'] ?? 'N/A',
                workshop['total_sessions']?.toString() ?? '0',
                registered.toString(),
                '$attended (${registered > 0 ? (attended / registered * 100).toStringAsFixed(1) : 0}%)',
                rating,
              ];
            }).toList(),
          ],
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
          },
          border: pw.TableBorder.all(color: grey200, width: 0.5),
          headerPadding: const pw.EdgeInsets.all(8),
          cellPadding: const pw.EdgeInsets.all(8),
        ),
      ],
    );
  }
}

// Material Icons codepoints for PDF generation
class PdfIcons {
  // Using Unicode code points for Material Icons
  static const int work = 0xE8F9; // Work icon
  static const int event = 0xE878; // Event icon
  static const int people = 0xE7FB; // People icon
  static const int percent = 0xE93C;

  static int star = 0xE838; // Star icon
}
