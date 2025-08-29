import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

// Helper class for gender distribution data
class GenderData {
  final String gender;
  final int count;
  final double percentage;
  final PdfColor color;

  const GenderData({
    required this.gender,
    required this.count,
    required this.percentage,
    required this.color,
  });
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

class ParticipantAnalyticsPdfGenerator {
  // Define colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1A73E8);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF34A853);
  static const PdfColor accentColor = PdfColor.fromInt(0xFFFBBC05);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFEA4335);
  static const PdfColor grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor grey800 = PdfColor.fromInt(0xFF424242);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);

  // Main method to generate PDF
  static Future<Uint8List> generatePdf(
    Map<String, dynamic> analyticsData,
  ) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Add page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (pw.Context context) => [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildOverviewMetrics(analyticsData),
              pw.SizedBox(height: 20),
              if ((analyticsData['top_10_participants'] as List?)?.isNotEmpty ??
                  false)
                _buildTopParticipants(analyticsData['top_10_participants']),
              pw.SizedBox(height: 20),
              if (analyticsData['gender_distribution'] != null)
                _buildGenderDistribution(analyticsData['gender_distribution']),
              pw.SizedBox(height: 20),
              if (analyticsData['district_histogram'] != null)
                _buildDistrictHistogram(analyticsData['district_histogram']),
            ],
      ),
    );

    // Save the PDF
    return pdf.save();
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
              PdfIcons.people,
            ),
            _buildMetricCard(
              'Attendance %',
              '${data['attendance_percentage']?.toStringAsFixed(1) ?? '0'}%',
              PdfIcons.check_circle,
              color: secondaryColor,
            ),
            _buildMetricCard(
              'Feedback Response Rate',
              '${data['feedback_response_rate']?.toStringAsFixed(1) ?? '0'}%',
              PdfIcons.feedback,
              color: accentColor,
            ),
          ],
        ),
      ],
    );
  }

  // Metric card widget
  static pw.Widget _buildMetricCard(
    String title,
    String value,
    int icon, {
    PdfColor color = primaryColor,
  }) {
    return pw.Container(
      width: 150,
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
              pw.Text(
                String.fromCharCode(icon),
                style: pw.TextStyle(
                  font: PdfIcons.font,
                  fontSize: 18,
                  color: color,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: const pw.TextStyle(fontSize: 12, color: grey600),
              ),
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
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(4),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
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
              final index = entry.key;
              final participant = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index.isOdd ? grey300 : white,
                ),
                children: [
                  _buildTableCell((index + 1).toString()),
                  _buildTableCell(participant['name']?.toString() ?? 'N/A'),
                  _buildTableCell(participant['email']?.toString() ?? 'N/A'),
                  _buildTableCell('${participant['attended_sessions'] ?? 0}'),
                  _buildTableCell('${participant['registered_sessions'] ?? 0}'),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Gender distribution section
  static pw.Widget _buildGenderDistribution(Map<String, dynamic> distribution) {
    final total = distribution.values.fold<int>(
      0,
      (sum, value) => sum + (value is int ? value : 0),
    );

    final data =
        distribution.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0;
          return GenderData(
            gender: entry.key,
            count: entry.value is int ? entry.value : 0,
            percentage: percentage,
            color: _getGenderColor(entry.key),
          );
        }).toList();

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
            // Pie chart placeholder
            pw.Container(
              width: 200,
              height: 200,
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'Pie Chart\n(Visualization not implemented)',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            // Legend
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children:
                    data.map((item) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 12,
                              height: 12,
                              color: item.color,
                              margin: const pw.EdgeInsets.only(right: 8),
                            ),
                            pw.Text(
                              '${item.gender}: ${item.count} (${item.percentage.toStringAsFixed(1)}%)',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(5),
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
        return const PdfColor.fromInt(0x34A853); // Green
    }
  }
}
