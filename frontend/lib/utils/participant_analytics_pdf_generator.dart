import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

class ParticipantAnalyticsPdfGenerator {
  // Define colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1A73E8);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF34A853);
  static const PdfColor accentColor = PdfColor.fromInt(0xFFFBBC05);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFEA4335);
  static const PdfColor positiveColor = PdfColor.fromInt(0xFF34A853);
  static const PdfColor grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor grey800 = PdfColor.fromInt(0xFF424242);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);

  // Fonts
  final pw.Font normalFont;
  final pw.Font boldFont;

  // Data
  final Map<String, dynamic> analyticsData;

  // Constructor
  ParticipantAnalyticsPdfGenerator({
    required this.analyticsData,
    required this.normalFont,
    required this.boldFont,
  });

  // Main method to generate PDF
  static Future<Uint8List> generatePdf(
    Map<String, dynamic> analyticsData,
  ) async {
    // Create a PDF document
    final pdf = pw.Document();

    try {
      // Load fonts and create theme
      final font = await _loadFont();
      final theme = pw.ThemeData.withFont(base: font);

      // Get all participants to calculate type distribution
      final participants = await _fetchAllParticipants();
      final typeDistribution = _calculateTypeDistribution(participants);

      // Add the type distribution to analytics data
      final updatedAnalyticsData = Map<String, dynamic>.from(analyticsData);
      updatedAnalyticsData['participant_type_distribution'] = typeDistribution;

      // Add page with all content
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build:
              (pw.Context context) => [
                _buildHeader(),
                pw.SizedBox(height: 20),
                _buildOverviewMetrics(updatedAnalyticsData),
                pw.SizedBox(height: 20),
                if ((updatedAnalyticsData['top_10_participants'] as List?)
                        ?.isNotEmpty ??
                    false)
                  _buildTopParticipants(
                    updatedAnalyticsData['top_10_participants'],
                  ),
                pw.SizedBox(height: 20),
                if (updatedAnalyticsData['gender_distribution'] != null)
                  _buildGenderDistribution(
                    updatedAnalyticsData['gender_distribution'],
                  ),
                pw.SizedBox(height: 20),
                if (updatedAnalyticsData['district_histogram'] != null)
                  _buildDistrictHistogram(
                    updatedAnalyticsData['district_histogram'],
                  ),
                pw.SizedBox(height: 20),
                if (typeDistribution.isNotEmpty)
                  _buildParticipantTypeDistribution(typeDistribution),
              ],
        ),
      );
    } catch (e) {
      // If there's an error, still generate the PDF with available data
      print('Error generating PDF: $e');
      final font = await _loadFont();
      final theme = pw.ThemeData.withFont(base: font);

      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build:
              (pw.Context context) => [
                _buildHeader(),
                pw.SizedBox(height: 20),
                _buildOverviewMetrics(analyticsData),
                pw.SizedBox(height: 20),
                if ((analyticsData['top_10_participants'] as List?)
                        ?.isNotEmpty ??
                    false)
                  _buildTopParticipants(analyticsData['top_10_participants']),
                pw.SizedBox(height: 20),
                if (analyticsData['gender_distribution'] != null)
                  _buildGenderDistribution(
                    analyticsData['gender_distribution'],
                  ),
                pw.SizedBox(height: 20),
                if (analyticsData['district_histogram'] != null)
                  _buildDistrictHistogram(analyticsData['district_histogram']),
              ],
        ),
      );
    }

    // Save the PDF
    return pdf.save();
  }

  // Fetch all participants from the API
  static Future<List<dynamic>> _fetchAllParticipants() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/participants/'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching participants: $e');
    }
    return [];
  }

  // Calculate participant type distribution
  static Map<String, int> _calculateTypeDistribution(
    List<dynamic> participants,
  ) {
    final typeCounts = <String, int>{};

    for (final participant in participants) {
      final type =
          participant['participant_type']?['name']?.toString() ?? 'Unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    return typeCounts;
  }

  // Header section
  static pw.Widget _buildHeader() {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Participants Analytics Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on ${dateFormat.format(now)} at ${timeFormat.format(now)}',
          style: const pw.TextStyle(fontSize: 10, color: grey600),
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  // Overview metrics section
  static pw.Widget _buildOverviewMetrics(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Overview',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricCard(
              'Total Participants',
              '${data['total_participants'] ?? 0}',
            ),
            _buildMetricCard(
              'Attendance %',
              '${data['attendance_percentage']?.toStringAsFixed(1) ?? '0'}%',
            ),
            _buildMetricCard(
              'Feedback Response Rate',
              '${data['feedback_response_rate']?.toStringAsFixed(1) ?? '0'}%',
            ),
          ],
        ),
      ],
    );
  }

  // Metric card widget
  static pw.Widget _buildMetricCard(String title, String value) {
    return pw.Container(
      width: 175,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: white,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [pw.BoxShadow(color: grey300, blurRadius: 4)],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 12, color: grey600)),
              pw.SizedBox(width: 8),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Top participants section
  static pw.Widget _buildTopParticipants(List<dynamic> participants) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top 10 Participants',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(4),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: grey200),
              children: [
                _buildTableHeaderCell('#'),
                _buildTableHeaderCell('Name'),
                _buildTableHeaderCell('Email'),
                _buildTableHeaderCell('Attended'),
                _buildTableHeaderCell('Registered'),
              ],
            ),
            // Data rows
            ...participants.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final participant = entry.value;
              return pw.TableRow(
                children: [
                  _buildTableCell(index.toString()),
                  _buildTableCell(participant['name']),
                  _buildTableCell(participant['email']),
                  _buildTableCell(participant['attended_sessions'].toString()),
                  _buildTableCell(
                    participant['registered_sessions'].toString(),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Gender distribution section
  static pw.Widget _buildGenderDistribution(Map<String, dynamic> genderData) {
    final entries = genderData.entries.toList();
    final total = entries.fold(0, (sum, entry) => sum + (entry.value as int));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Gender Distribution',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Simple bar chart
            pw.Container(
              width: 200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var entry in entries)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${entry.key}: ${entry.value} (${total > 0 ? ((entry.value as int) / total * 100).toStringAsFixed(1) : 0}%)',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFF424242),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            height: 12,
                            width:
                                total > 0
                                    ? 200 * (entry.value as int) / total
                                    : 0,
                            decoration: pw.BoxDecoration(
                              color: _getGenderColor(entry.key),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // District histogram section
  static pw.Widget _buildDistrictHistogram(Map<String, dynamic> histogram) {
    final entries =
        histogram.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final maxValue = entries.isNotEmpty ? entries.first.value as int : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Participants by District',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: grey200),
              children: [
                _buildTableHeaderCell('District'),
                _buildTableHeaderCell('Count'),
                _buildTableHeaderCell(''),
              ],
            ),
            // Data rows
            ...entries.map((entry) {
              final percentage =
                  maxValue > 0 ? (entry.value as int) / maxValue * 100 : 0;
              return pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell(entry.value.toString()),
                  pw.Container(
                    height: 20,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          width: percentage * 3, // Scale the width
                          color: primaryColor,
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                          child: pw.Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Helper to build table header cell
  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: grey800,
        ),
      ),
    );
  }

  // Helper to build table data cell
  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  // Helper to get color based on participant type
  static PdfColor _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'student':
        return const PdfColor.fromInt(0x4285F4); // Blue
      case 'teacher':
        return const PdfColor.fromInt(0xEA4335); // Red
      case 'professional':
        return const PdfColor.fromInt(0xFBBC05); // Yellow
      case 'industry':
        return const PdfColor.fromInt(0x34A853); // Green
      default:
        return const PdfColor.fromInt(0x9E9E9E); // Grey for unknown types
    }
  }

  // Helper to get color based on gender
  static PdfColor _getGenderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return const PdfColor.fromInt(0x4285F4); // Blue
      case 'female':
        return const PdfColor.fromInt(0xEA4335); // Red
      case 'other':
        return const PdfColor.fromInt(0xFBBC05); // Yellow
      default:
        return const PdfColor.fromInt(0x9E9E9E); // Grey for unknown
    }
  }

  // Participant type distribution section
  static pw.Widget _buildParticipantTypeDistribution(
    Map<String, dynamic> typeData,
  ) {
    final entries = typeData.entries.toList();
    final total = entries.fold(0, (sum, entry) => sum + (entry.value as int));

    // Sort by count (descending)
    entries.sort((a, b) => (b.value as int).compareTo(a.value as int));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Participant Type Distribution',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Stacked bar chart
            pw.Container(
              width: 300,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Stacked bars
                  pw.Container(
                    height: 30,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Row(
                      children:
                          entries.map((entry) {
                            final percentage =
                                total > 0 ? (entry.value as int) / total : 0;
                            return pw.Container(
                              width: 300.0 * percentage,
                              decoration: pw.BoxDecoration(
                                color: _getTypeColor(entry.key),
                                borderRadius:
                                    percentage == 1
                                        ? const pw.BorderRadius.all(
                                          pw.Radius.circular(4),
                                        )
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  // Legend
                  ...entries.map((entry) {
                    final count = entry.value as int;
                    final percentage =
                        total > 0
                            ? (count / total * 100).toStringAsFixed(1)
                            : '0.0';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            decoration: pw.BoxDecoration(
                              color: _getTypeColor(entry.key),
                              shape: pw.BoxShape.rectangle,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(2),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '${entry.key}: $count ($percentage%)',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColor.fromInt(0x8A000000), // 54% black
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Load font (you'll need to implement this based on your font setup)
  static Future<pw.Font> _loadFont() async {
    // This is a placeholder - implement based on your font setup
    return pw.Font.courier();
  }
}

// Material Icons codepoints for PDF generation
class PdfIcons {
  static const int people = 0xe7ef;
  static const int check_circle = 0xe86c;
  static const int feedback = 0xe0b7;

  // Font reference (you'll need to load this font in _loadFont)
  static pw.Font? _font;

  static pw.Font get font => _font ?? pw.Font.courier();
}
