import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' show PdfPoint;

// Material Icons codepoints
class PdfIcons {
  static const int event = 0xe878;
  static const int people = 0xe7ef;
  static const int check_circle = 0xe86c;
  static const int feedback = 0xe0b9;
}

class SessionReportPdfGenerator {
  // Define colors as class properties
  final PdfColor primaryColor = PdfColor.fromInt(0xFF1976D2);
  final PdfColor blueShade50 = PdfColor.fromInt(0xFFE3F2FD);
  final PdfColor blueShade800 = PdfColor.fromInt(0xFF1565C0);
  final PdfColor greyShade100 = PdfColor.fromInt(0xFFF5F5F5);
  final PdfColor greyShade300 = PdfColor.fromInt(0xFFE0E0E0);
  final PdfColor black54 = PdfColor.fromInt(0xFF757575);
  final PdfColor blue400 = PdfColor.fromInt(0xFF42A5F5);
  final PdfColor green400 = PdfColor.fromInt(0xFF66BB6A);
  final PdfColor orange400 = PdfColor.fromInt(0xFFFFA726);

  // Report data
  final Map<String, dynamic> reportData;

  // Constructor
  SessionReportPdfGenerator(this.reportData);

  // Static method to generate PDF
  static Future<Uint8List> generatePdf(dynamic reportData) async {
    // Convert Map<dynamic, dynamic> to Map<String, dynamic>
    final Map<String, dynamic> typedData = Map<String, dynamic>.from(
      reportData as Map,
    );
    final generator = SessionReportPdfGenerator(typedData);
    return generator._generatePdf();
  }

  // Private instance method to generate PDF
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final dailyBreakdown = Map<String, dynamic>.from(
      reportData['daily_breakdown'] ?? {},
    );
    final totalSessions = reportData['total_sessions'] ?? 0;
    final totalRegistered = reportData['total_registered'] ?? 0;
    final totalAttended = reportData['total_attended'] ?? 0;
    final totalFeedback = reportData['total_feedback'] ?? 0;
    // Get and format date strings
    final startDateStr = reportData['date_from'] as String?;
    final endDateStr = reportData['date_to'] as String?;

    // Format dates if they exist
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'N/A';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('MMMM d, yyyy').format(date);
      } catch (e) {
        return dateStr; // Return original string if parsing fails
      }
    }

    final startDateTime = formatDate(startDateStr);
    final endDateTime = formatDate(endDateStr);

    // Helper function to build header
    pw.Widget _buildHeader() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Session Report',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Time Period: $startDateTime - $endDateTime',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.blue800),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 10, color: black54),
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: greyShade300),
        ],
      );
    }

    // Helper function to build metric cards
    pw.Widget _buildMetricCard(String title, String value, int iconCode) {
      return pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 5),
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              blurRadius: 5,
              offset: const PdfPoint(0, 2),
            ),
          ],
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Icon(pw.IconData(iconCode), size: 24, color: blueShade800),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: blueShade800,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 12, color: black54),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Helper function to build metric chip
    pw.Widget _buildMetricChip(
      dynamic icon,
      String label,
      String value,
      PdfColor color,
    ) {
      // Create a lighter version of the color for the background
      final PdfColor lightColor = PdfColor(
        color.red * 0.1 + 0.9,
        color.green * 0.1 + 0.9,
        color.blue * 0.1 + 0.9,
      );

      // Create a semi-transparent version of the color for the border
      final PdfColor borderColor = PdfColor(
        color.red * 0.5,
        color.green * 0.5,
        color.blue * 0.5,
      );

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: lightColor,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: borderColor),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            if (icon != null) pw.Icon(icon, size: 16, color: color),
            if (icon != null) pw.SizedBox(width: 6),
            pw.Text(
              '$label: $value',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Helper function to build daily breakdown card
    pw.Widget _buildDailyBreakdownCard(
      String date,
      Map<String, dynamic> metrics,
    ) {
      return pw.SizedBox(
        width: 200,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: greyShade300),
            borderRadius: pw.BorderRadius.circular(12),
            color: PdfColors.white,
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.grey300,
                blurRadius: 8,
                offset: const PdfPoint(0, 2),
              ),
            ],
          ),
          margin: const pw.EdgeInsets.all(0),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      date,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Icon(
                      const pw.IconData(0xe923),
                      color: black54,
                      size: 16,
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                _buildMetricChip(
                  pw.IconData(0xe878),
                  'Sessions',
                  '${metrics['sessions'] ?? 0}',
                  PdfColors.blue,
                ),
                pw.SizedBox(height: 8),
                _buildMetricChip(
                  pw.IconData(0xe7fe),
                  'Registered',
                  '${metrics['registered'] ?? 0}',
                  green400,
                ),
                pw.SizedBox(height: 8),
                _buildMetricChip(
                  pw.IconData(0xe86c),
                  'Attended',
                  '${metrics['attended'] ?? 0}',
                  PdfColors.teal,
                ),
                pw.SizedBox(height: 8),
                _buildMetricChip(
                  pw.IconData(0xe0b9),
                  'Feedback',
                  '${metrics['feedback'] ?? 0}',
                  orange400,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Page 1: Overview, Metrics, and Funnel
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [blueShade50, PdfColors.white],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                _buildHeader(),
                pw.SizedBox(height: 30),
                // Key Metrics
                pw.Text(
                  'Session Overview',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: blueShade800,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children:
                      [
                        _buildMetricCard(
                          'Total Sessions',
                          totalSessions.toString(),
                          PdfIcons.event,
                        ),
                        _buildMetricCard(
                          'Registered',
                          totalRegistered.toString(),
                          PdfIcons.people,
                        ),
                        _buildMetricCard(
                          'Attended',
                          totalAttended.toString(),
                          PdfIcons.check_circle,
                        ),
                        _buildMetricCard(
                          'Feedback',
                          totalFeedback.toString(),
                          PdfIcons.feedback,
                        ),
                      ].map((e) => pw.Expanded(child: e)).toList(),
                ),
                pw.SizedBox(height: 30),
                // Funnel Chart
                pw.Text(
                  'Session Funnel',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: blueShade800,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: greyShade300, width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  padding: const pw.EdgeInsets.all(14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.SizedBox(
                        height: 200,
                        child: FunnelBarChart(
                          reportData: reportData,
                          width: 300,
                          height: 200,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Page 2: Daily Breakdown (if available)
    if (dailyBreakdown.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [blueShade50, PdfColors.white],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Daily Breakdown',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: blueShade800,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: greyShade300, width: 1),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    padding: const pw.EdgeInsets.all(14),
                    child: pw.Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children:
                          dailyBreakdown.entries
                              .map<pw.Widget>(
                                (entry) => _buildDailyBreakdownCard(
                                  entry.key,
                                  Map<String, dynamic>.from(entry.value),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}

// Funnel chart widget to visualize session progression
class FunnelBarChart extends pw.StatelessWidget {
  final Map<String, dynamic> reportData;
  final double width;
  final double height;

  FunnelBarChart({
    required this.reportData,
    this.width = 500,
    this.height = 300,
  });

  @override
  pw.Widget build(pw.Context context) {
    // Use session overview data
    (reportData['total_sessions'] ?? 0).toDouble();
    final totalRegistered = (reportData['total_registered'] ?? 0).toDouble();
    final totalAttended = (reportData['total_attended'] ?? 0).toDouble();
    final totalFeedback = (reportData['total_feedback'] ?? 0).toDouble();

    // Calculate conversion rates and maximum value
    final maxValue = [
      totalRegistered,
      totalAttended,
      totalFeedback,
    ].fold(0.0, (a, b) => a > b ? a : b);

    final attendedToFeedback =
        totalRegistered > 0
            ? (totalAttended / totalRegistered * 100).toStringAsFixed(1)
            : '0.0';
    final feedbackRate =
        totalAttended > 0
            ? (totalFeedback / totalAttended * 100).toStringAsFixed(1)
            : '0.0';

    return pw.Container(
      width: double.infinity,
      height: height,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 8,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title and overall conversion
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Session Funnel Analysis',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Funnel visualization
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildStep(
                  value: totalRegistered,
                  label: 'Registered: ',
                  color: PdfColor.fromInt(0xFF66BB6A),
                  isFirst: true,
                  maxValue: maxValue,
                ),
                _buildArrow(attendedToFeedback),
                _buildStep(
                  value: totalAttended,
                  label: 'Attended: ',
                  color: PdfColor.fromInt(0xFFFFA000),
                  maxValue: maxValue,
                ),
                _buildArrow(feedbackRate),
                _buildStep(
                  value: totalFeedback,
                  label: 'Feedback: ',
                  color: PdfColor.fromInt(0xFFE53935),
                  isLast: true,
                  maxValue: maxValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStep({
    required double value,
    required String label,
    required PdfColor color,
    required double maxValue,
    bool isFirst = false,
    bool isLast = false,
  }) {
    // Calculate bar height based on relative value
    final barHeight = height * 0.4 * (value / (maxValue > 0 ? maxValue : 1));
    final barWidth = 80.0;
    final topLeft = isFirst ? 8.0 : 0.0;
    final topRight = isLast ? 8.0 : 0.0;
    final barContainerHeight = height * 0.4; // Fixed height for container

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Label with value
        pw.Container(
          padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                value.toInt().toString(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Bar container with fixed height
        pw.Container(
          width: barWidth,
          height: barContainerHeight,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(topLeft),
              topRight: pw.Radius.circular(topRight),
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Stack(
            children: [
              // Actual bar with gradient
              pw.Align(
                alignment: pw.Alignment.bottomCenter,
                child: pw.Container(
                  height: barHeight,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        color,
                        PdfColor(
                          color.red * 0.8,
                          color.green * 0.8,
                          color.blue * 0.8,
                        ),
                      ],
                      begin: pw.Alignment.topCenter,
                      end: pw.Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey400,
                        blurRadius: 4,
                        offset: const PdfPoint(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildArrow(String conversionRate) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 40),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '↓ $conversionRate%',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '>>',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }
}
