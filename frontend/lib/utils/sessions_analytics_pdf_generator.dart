import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SessionsAnalyticsPdfGenerator {
  // Define colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1A73E8);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF34A853);
  static const PdfColor accentColor = PdfColor.fromInt(0xFFFBBC05);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFEA4335);
  static const PdfColor positiveColor = PdfColor.fromInt(
    0xFF34A853,
  ); // Same as secondaryColor
  static const PdfColor grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor grey800 = PdfColor.fromInt(0xFF424242);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);

  // Fonts
  final pw.Font normalFont;
  final pw.Font boldFont;

  // Data fields
  final Map<String, dynamic> overviewData;
  final List<dynamic> sessionsList;

  // Helper method to safely get an integer from a map
  int _safeGetInt(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return 0;
    final value = map[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method to safely get a double from a map
  double _safeGetDouble(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return 0.0;
    final value = map[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Constructor
  SessionsAnalyticsPdfGenerator({
    required this.overviewData,
    required this.sessionsList,
  }) : normalFont = pw.Font.courier(),
       boldFont = pw.Font.courierBold();

  // Static method to generate PDF
  static Future<Uint8List> generatePdf({
    required Map<String, dynamic> overviewData,
    required List<dynamic> sessionsList,
  }) async {
    final generator = SessionsAnalyticsPdfGenerator(
      overviewData: overviewData,
      sessionsList: sessionsList,
    );
    return generator._generatePdf();
  }

  // Main PDF generation method
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 1.5 * PdfPageFormat.cm,
          marginLeft: 1.5 * PdfPageFormat.cm,
          marginRight: 1.5 * PdfPageFormat.cm,
          marginBottom: 1.5 * PdfPageFormat.cm,
        ),
        build:
            (context) => [
              // Header
              _buildHeader(dateFormat.format(now), timeFormat.format(now)),
              pw.SizedBox(height: 20),

              // Sessions Overview Section
              _buildSectionTitle('Sessions Overview'),
              pw.SizedBox(height: 12),
              _buildOverviewCards(),
              pw.SizedBox(height: 20),

              // Session Funnel Section
              _buildSectionTitle('Session Funnel'),
              pw.SizedBox(height: 12),
              _buildSessionFunnel(),
              pw.SizedBox(height: 20),

              // Attendance Rate Section
              _buildSectionTitle('Attendance Rate'),
              pw.SizedBox(height: 12),
              _buildAttendanceRateChart(),
              pw.SizedBox(height: 20),

              // Attendance Per Session Section
              _buildSectionTitle('Attendance Per Session'),
              pw.SizedBox(height: 12),
              _buildAttendancePerSessionChart(),
              pw.SizedBox(height: 20),

              // Sessions List Section
              _buildSectionTitle('Sessions List'),
              pw.SizedBox(height: 12),
              _buildSessionsList(),
            ],
      ),
    );

    return pdf.save();
  }

  // Helper methods for building PDF components
  pw.Widget _buildHeader(String date, String time) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sessions Analytics Report',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on $date at $time',
          style: pw.TextStyle(fontSize: 10, color: grey600),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildOverviewCards() {
    final totalSessions = overviewData['total_sessions'] ?? 0;
    final totalRegistered = overviewData['total_registered'] ?? 0;
    final totalAttended = overviewData['total_attended'] ?? 0;
    final attendanceRate = overviewData['average_attendance_rate'] ?? 0.0;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard(
          'Total Sessions',
          totalSessions.toString(),
          PdfIcons.event,
        ),
        _buildMetricCard(
          'Total Registered',
          totalRegistered.toString(),
          PdfIcons.people,
        ),
        _buildMetricCard(
          'Total Attended',
          totalAttended.toString(),
          PdfIcons.check_circle,
        ),
        _buildMetricCard(
          'Avg. Attendance',
          '${attendanceRate.toStringAsFixed(1)}%',
          PdfIcons.bar_chart,
        ),
      ],
    );
  }

  pw.Widget _buildMetricCard(String title, String value, int iconCode) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Icon(pw.IconData(iconCode), size: 24, color: primaryColor),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, color: grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSessionFunnel() {
    final int totalRegistered = _safeGetInt(overviewData, 'total_registered');
    final int totalAttended = _safeGetInt(overviewData, 'total_attended');
    final int feedbackCount = _safeGetInt(overviewData, 'feedback_count');

    // Calculate max value for scaling
    final int maxValue = [
      totalRegistered,
      totalAttended,
      feedbackCount,
    ].reduce((a, b) => a > b ? a : b);
    final double maxValueD = maxValue.toDouble();

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildFunnelBar(
                'Registered',
                totalRegistered,
                maxValueD,
                primaryColor,
                isFirst: true,
              ),
              _buildFunnelBar(
                'Attended',
                totalAttended,
                maxValueD,
                positiveColor,
              ),
              _buildFunnelBar(
                'Feedback',
                feedbackCount,
                maxValueD,
                PdfColor.fromInt(0xFFFFA000), // Orange color for feedback
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Add a note about the funnel
          pw.Text(
            'Shows the progression from registration to attendance to feedback',
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

  pw.Widget _buildFunnelBar(
    String label,
    int value,
    double maxValue,
    PdfColor color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    const double maxBarHeight = 150.0;
    final double barHeight =
        maxValue > 0 ? (value / maxValue) * maxBarHeight : 0;
    const double barWidth = 60.0;
    final bool showValue = value > 0; // Only show value if > 0

    return pw.Container(
      width: barWidth + 20, // Add some padding
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Value label above the bar (only show if value > 0)
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
            pw.SizedBox(height: 20), // Keep consistent spacing

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
                    bottomLeft: pw.Radius.circular(4),
                    bottomRight: pw.Radius.circular(4),
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
                      bottomLeft: pw.Radius.circular(4),
                      bottomRight: pw.Radius.circular(4),
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
                // Conversion rate if not the last bar
                if (!isLast && showValue && value > 0)
                  pw.Text(
                    '${(value / maxValue * 100).toStringAsFixed(0)}%',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAttendanceRateChart() {
    final int totalRegistered = _safeGetInt(overviewData, 'total_registered');
    final int totalAttended = _safeGetInt(overviewData, 'total_attended');
    final double attendanceRate = _safeGetDouble(
      overviewData,
      'average_attendance_rate',
    );

    // Calculate attendance percentage
    final int registeredPercent =
        totalRegistered > 0
            ? ((totalAttended / totalRegistered) * 100).round()
            : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Registered vs. Attended',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${attendanceRate.toStringAsFixed(1)}% Attendance Rate',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildBarChartColumn(
                'Registered',
                100, // 100% baseline
                primaryColor, // Light blue color for registered
                0.8,
              ),
              _buildBarChartColumn(
                'Attended',
                registeredPercent.clamp(0, 100), // Ensure within 0-100 range
                positiveColor,
                0.8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAttendancePerSessionChart() {
    // Get attendance per session data from overview
    final List<dynamic> attendancePerSession =
        overviewData['attendance_per_session'] is List
            ? List<dynamic>.from(overviewData['attendance_per_session'])
            : [];
    final List<dynamic> sessionTitles =
        overviewData['session_titles'] is List
            ? List<dynamic>.from(overviewData['session_titles'])
            : [];

    if (attendancePerSession.isEmpty || sessionTitles.isEmpty) {
      return pw.Center(child: pw.Text('No attendance data available'));
    }

    // Create a list of session data with title and attendance
    final List<Map<String, dynamic>> sessionsWithAttendance = [];
    for (int i = 0; i < sessionTitles.length; i++) {
      if (i < attendancePerSession.length) {
        sessionsWithAttendance.add({
          'title': sessionTitles[i],
          'attendance_count': attendancePerSession[i],
        });
      }
    }

    // Sort by end date in descending order to get most recent first and take top 10
    sessionsWithAttendance.sort((a, b) {
      final aEnd = DateTime.tryParse(a['end_time'] ?? '') ?? DateTime(1970);
      final bEnd = DateTime.tryParse(b['end_time'] ?? '') ?? DateTime(1970);
      return bEnd.compareTo(aEnd);
    });
    final recentSessions = sessionsWithAttendance.take(10).toList();

    // Find the maximum attendance for scaling
    final double maxAttendance =
        recentSessions.isNotEmpty
            ? recentSessions
                .map((s) => (s['attendance_count'] as num).toDouble())
                .reduce((a, b) => a > b ? a : b)
            : 1.0;

    return pw.Container(
      height: 200,
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [pw.Text('10 Most Recent Sessions by Attendance')],
          ),
          pw.SizedBox(height: 12),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < recentSessions.length; i++)
                  pw.Expanded(
                    child: _buildSessionBar(
                      recentSessions[i],
                      maxAttendance,
                      i == recentSessions.length - 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSessionBar(
    Map<String, dynamic> session,
    double maxValue,
    bool isLast,
  ) {
    final sessionName =
        session['title']?.toString().split(' ').take(2).join(' ') ?? 'Session';
    final attendance = (session['attendance_count'] as num).toDouble();

    // Fixed dimensions
    const double barContainerHeight = 120.0;
    const double barWidth = 30.0;

    // Calculate bar height as a percentage of the container
    final double barHeight =
        maxValue > 0 ? (attendance / maxValue) * barContainerHeight : 0;

    return pw.Container(
      width: 50, // Slightly wider to accommodate the bar and some padding
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Value label above the bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const pw.EdgeInsets.only(bottom: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.green,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              attendance.toStringAsFixed(0), // Show as integer
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          // Bar container
          pw.Container(
            width: barWidth,
            height: barHeight,
            margin: const pw.EdgeInsets.only(bottom: 0),
            decoration: pw.BoxDecoration(
              color: PdfColors.green,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
          ),
          // Session name label
          pw.Container(
            width: barWidth + 20, // Slightly wider than the bar
            margin: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              sessionName,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, height: 1.2),
              maxLines: 3,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBarChartColumn(
    String label,
    int value,
    PdfColor color,
    double widthFactor,
  ) {
    const double barContainerHeight = 150.0;
    final double barHeight = value > 0 ? (value / 100) * barContainerHeight : 0;
    final double barWidth = 60.0 * widthFactor;

    return pw.Container(
      width: barWidth + 20, // Add some padding
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Value label above the bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '$value%',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 4),
          // Bar container with fixed height
          pw.Container(
            width: barWidth,
            height: barContainerHeight,
            decoration: pw.BoxDecoration(
              color: grey200,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
                bottomLeft: pw.Radius.circular(4),
                bottomRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Stack(
              children: [
                // Actual bar
                pw.Positioned.fill(
                  bottom: 0,
                  child: pw.SizedBox(
                    height: barHeight,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(4),
                          topRight: pw.Radius.circular(4),
                          bottomLeft: pw.Radius.circular(4),
                          bottomRight: pw.Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          // Label
          pw.Container(
            height: 30, // Fixed height for label area
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 10, color: grey600),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSessionsList() {
    if (sessionsList.isEmpty) {
      return pw.Center(child: pw.Text('No sessions available'));
    }

    final List<String> headers = [
      'Session',
      'Location',
      'Registered',
      'Attended',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data:
          sessionsList.map((session) {
            final registered = session['registered_count'] ?? 0;
            final attended = session['attended_count'] ?? 0;

            return [
              session['title'] ?? 'N/A',
              session['location'] ?? 'N/A',
              registered.toString(),
              attended.toString(),
            ];
          }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: white,
      ),
      headerDecoration: pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(color: grey300, width: 0.5),
      headerPadding: const pw.EdgeInsets.all(4),
    );
  }
}

// Material Icons codepoints for PDF generation
class PdfIcons {
  static const int event = 0xe878;
  static const int people = 0xe7ef;
  static const int check_circle = 0xe86c;
  static const int bar_chart = 0xe26b;
}
