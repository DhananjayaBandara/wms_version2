import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TrainerAnalyticsPdfGenerator {
  // Colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF3F51B5);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF5C6BC0);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF7986CB);
  static const PdfColor grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor grey800 = PdfColor.fromInt(0xFF424242);

  // Main method to generate PDF
  static Future<Uint8List> generatePdf({
    required Map<String, dynamic> overviewData,
    required List<dynamic> trainersList,
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
              _buildSectionTitle('Trainers Overview'),
              pw.SizedBox(height: 16),
              _buildOverviewCards(overviewData),
              pw.SizedBox(height: 24),
              _buildTrainersList(trainersList),
            ],
      ),
    );

    return pdf.save();
  }

  // Generate PDF for individual trainer
  static Future<Uint8List> generateTrainerPdf({
    required Map<String, dynamic> trainerData,
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
        build: (pw.Context context) {
          final ratingsTrend =
              (trainerData['ratings_trend'] as List<dynamic>?) ?? [];

          return [
            _buildHeader(dateFormat.format(now), timeFormat.format(now)),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              '${trainerData['name'] ?? 'Trainer'}\'s Analytics',
            ),
            pw.SizedBox(height: 16),
            _buildTrainerInfoCard(trainerData),
            if (ratingsTrend.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildRatingsTrendChart(ratingsTrend),
              pw.SizedBox(height: 20),
              _buildRatingsDetails(ratingsTrend),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Header with date and time
  static pw.Widget _buildHeader(String date, String time) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Trainer Analytics Report',
              style: pw.TextStyle(
                fontSize: 24,
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
        ),
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: primaryColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              String.fromCharCode(PdfIcons.person),
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 24,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  // Overview cards
  static pw.Widget _buildOverviewCards(Map<String, dynamic> overview) {
    return pw.Row(
      children: [
        _buildMetricCard(
          'Total Trainers',
          '${overview['total_trainers'] ?? 0}',
          PdfIcons.people,
          0.45,
        ),
        pw.SizedBox(width: 12),
        _buildMetricCard(
          'Top Rated Trainer',
          overview['top_trainer']?.toString() ?? '-',
          PdfIcons.star,
          0.55,
        ),
      ],
    );
  }

  // Metric card
  static pw.Widget _buildMetricCard(
    String title,
    String value,
    int icon,
    double widthFactor,
  ) {
    return pw.Expanded(
      flex: (widthFactor * 100).toInt(),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4)],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  String.fromCharCode(icon),
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 20,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  title,
                  style: pw.TextStyle(color: grey600, fontSize: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  // Trainers list
  static pw.Widget _buildTrainersList(List<dynamic> trainers) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Trainers List'),
        pw.SizedBox(height: 12),
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
            0: const pw.FlexColumnWidth(2.5), // Name
            1: const pw.FlexColumnWidth(2.5), // Email
            2: const pw.FlexColumnWidth(1), // Sessions
            3: const pw.FlexColumnWidth(1), // Rating
          },
          data: [
            ['Name', 'Email', 'Sessions', 'Avg. Rating'],
            ...trainers.map((trainer) {
              final String trainerName = trainer['name'] ?? 'N/A';
              final String trainerEmail = trainer['email'] ?? 'N/A';
              final String trainerSessions = '${trainer['session_count'] ?? 0}';
              final String trainerRating =
                  trainer['avg_feedback_rating']?.toStringAsFixed(1) ?? '-';
              return [
                trainerName,
                trainerEmail,
                trainerSessions,
                trainerRating,
              ];
            }).toList(),
          ],
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
          border: pw.TableBorder.all(color: grey200, width: 0.5),
          headerPadding: const pw.EdgeInsets.all(8),
          cellPadding: const pw.EdgeInsets.all(8),
        ),
      ],
    );
  }

  // Trainer info card
  static pw.Widget _buildTrainerInfoCard(Map<String, dynamic> trainer) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4)],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trainer Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    String.fromCharCode(PdfIcons.person),
                    style: pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 24,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      trainer['name'] ?? 'Trainer',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Email: ${trainer['email'] ?? '-'}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Sessions Conducted: ${trainer['session_count'] ?? 0}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Total Participants: ${trainer['total_participants'] ?? 0}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Average Rating: ${trainer['avg_feedback_rating']?.toStringAsFixed(1) ?? '-'}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
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
  }

  // Ratings trend chart
  static pw.Widget _buildRatingsTrendChart(List<dynamic> ratingsTrend) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4)],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Feedback Ratings Trend',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),
          // Bar chart implementation with proper alignment and labels
          pw.Container(
            height: 300,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Chart area with Y-axis and bars
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(width: 4),
                      // Bars container
                      pw.Expanded(
                        child: pw.Container(
                          height: double.infinity,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              left: pw.BorderSide(
                                width: 1,
                                color: PdfColors.grey400,
                              ),
                              bottom: pw.BorderSide(
                                width: 1,
                                color: PdfColors.grey400,
                              ),
                            ),
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            children: List.generate(ratingsTrend.length, (
                              index,
                            ) {
                              final rating =
                                  ratingsTrend[index]['avg_rating']
                                      ?.toDouble() ??
                                  0.0;
                              final height =
                                  (rating / 5.0) *
                                  100; // Scale height to fit in 200px

                              return pw.Column(
                                mainAxisSize: pw.MainAxisSize.max,
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  // Rating value above the bar
                                  pw.Container(
                                    margin: const pw.EdgeInsets.only(bottom: 2),
                                    child: pw.Text(
                                      rating.toStringAsFixed(1),
                                      style: const pw.TextStyle(fontSize: 8),
                                    ),
                                  ),
                                  // The bar
                                  pw.Container(
                                    width: 30,
                                    height: height,
                                    margin: const pw.EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor.fromInt(0xFF3F51B5),
                                      borderRadius:
                                          const pw.BorderRadius.vertical(
                                            top: pw.Radius.circular(4),
                                          ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // X-axis labels
                pw.Container(
                  height: 40,
                  margin: const pw.EdgeInsets.only(top: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: List.generate(ratingsTrend.length, (index) {
                      return pw.Container(
                        width: 30,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          ratingsTrend[index]['session_title']?.toString() ??
                              'Session',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ratings details table
  static pw.Widget _buildRatingsDetails(List<dynamic> ratingsTrend) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Session Ratings',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              boxShadow: [
                pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4),
              ],
            ),
            child: pw.TableHelper.fromTextArray(
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
                0: const pw.FlexColumnWidth(3), // Session
                1: const pw.FlexColumnWidth(2), // Date
                2: const pw.FlexColumnWidth(1), // Rating
              },
              data: [
                ['Session', 'Rating'],
                ...ratingsTrend.map((rating) {
                  return [
                    rating['session_title']?.toString() ?? 'Session',
                    rating['avg_rating']?.toStringAsFixed(1) ?? '-',
                  ];
                }).toList(),
              ],
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: grey200, width: 0.5),
              headerPadding: const pw.EdgeInsets.all(8),
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  // Load font
  static Future<pw.Font> _loadFont() async {
    // This is a placeholder - in a real app, you would load your custom font here
    return pw.Font.helvetica();
  }
}

// Icons used in the PDF
class PdfIcons {
  static const int person = 0xE7FD; // Person icon
  static const int people = 0xE7FB; // People icon
  static const int star = 0xE838; // Star icon
  static const int work = 0xE8F9; // Work icon
  static const int event = 0xE878; // Event icon
  static const int percent = 0xE93C; // Percent icon
}
