import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SessionPdfGenerator {
  static Future<Uint8List> generatePdf(Map<String, dynamic> detail) async {
    final pdf = pw.Document();

    // Get data from the detail map
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
    final ratingDist = detail['feedback_rating_distribution'] as Map? ?? {};
    final suggestions = detail['feedback_suggestions'] as List?;
    final participants = detail['participants'] as List?;

    // Page 1: Session Information and Funnel
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(detail),
              pw.SizedBox(height: 20),
              _buildSessionInfoCard(detail, registered, attended),
              pw.SizedBox(height: 20),
              _buildFunnelCard(registered, attended, feedbackParticipants),
            ],
          );
        },
      ),
    );

    // Page 2: Attendance and Rating Distribution
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Session Analytics',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildAttendanceCard(
                attendedPercent,
                absentPercent,
                attended,
                absent,
              ),
              if (ratingDist.isNotEmpty) pw.SizedBox(height: 20),
              if (ratingDist.isNotEmpty)
                _buildRatingDistributionCard(ratingDist),
            ],
          );
        },
      ),
    );

    // Page 3: Suggestions and Participants (if available)
    if ((suggestions?.isNotEmpty ?? false) ||
        (participants?.isNotEmpty ?? false)) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Additional Information',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 20),
                if ((suggestions?.isNotEmpty ?? false))
                  _buildSuggestionsCard(suggestions!),
                if ((participants?.isNotEmpty ?? false))
                  pw.SizedBox(height: 20),
                if ((participants?.isNotEmpty ?? false))
                  _buildParticipantsCard(participants!),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildHeader(Map<String, dynamic> detail) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          detail['title'] ?? 'Session Details',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          'Generated: ${DateTime.now().toString()}',
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildSessionInfoCard(
    Map<String, dynamic> detail,
    int registered,
    int attended,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Session Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text(
                'Workshop: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(detail['workshop'] ?? 'N/A'),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text(
                'Date & Time: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(detail['date_time'] ?? 'N/A'),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text(
                'Location: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(detail['location'] ?? 'Online'),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
      ),
    );
  }

  static pw.Widget _buildFunnelCard(
    int registered,
    int attended,
    int feedbackParticipants,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Session Funnel',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Funnel visualization with text arrows
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildFunnelStep('Registered', registered, PdfColors.blue400),
              pw.Text('>', style: pw.TextStyle(fontSize: 20)),
              _buildFunnelStep('Attended', attended, PdfColors.green400),
              pw.Text('>', style: pw.TextStyle(fontSize: 20)),
              _buildFunnelStep(
                'Feedback',
                feedbackParticipants,
                PdfColors.orange400,
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Funnel percentages
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Text(
                '100%',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${registered > 0 ? (attended / registered * 100).toStringAsFixed(1) : 0}%',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${attended > 0 ? (feedbackParticipants / attended * 100).toStringAsFixed(1) : 0}%',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFunnelStep(String label, int count, PdfColor color) {
    return pw.Container(
      child: pw.Column(
        children: [
          pw.Container(
            width: 80,
            height: 40,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              count.toString(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _buildAttendanceCard(
    int attendedPercent,
    int absentPercent,
    int attended,
    int absent,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Attendance Distribution',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Simplified attendance visualization
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              // Percentage display
              pw.Container(
                width: 150,
                height: 150,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.grey100,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$attendedPercent%',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ),
              ),

              // Legend
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        color: PdfColors.green,
                        margin: pw.EdgeInsets.only(right: 8),
                      ),
                      pw.Text('Attended: $attended ($attendedPercent%)'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        color: PdfColors.red,
                        margin: pw.EdgeInsets.only(right: 8),
                      ),
                      pw.Text('Absent: $absent ($absentPercent%)'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRatingDistributionCard(Map ratingDist) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey100,
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Feedback Rating Distribution',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // Chart title and description
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Rating',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Count',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Bar chart
          pw.Container(
            height: 250,
            child: pw.Column(
              children: [
                // Bars
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: List.generate(10, (index) {
                      final rating = index + 1;
                      final value = ratingDist[rating.toString()] ?? 0;

                      return pw.Expanded(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: _getRatingPdfColor(rating),
                                borderRadius: pw.BorderRadius.vertical(
                                  top: pw.Radius.circular(4),
                                ),
                              ),
                              margin: pw.EdgeInsets.symmetric(horizontal: 4),
                              child: pw.Center(
                                child: pw.Text(
                                  value.toInt().toString(),
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${rating}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Summary statistics
          pw.SizedBox(height: 16),
          pw.Text(
            'Summary:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Feedback: ${ratingDist.values.fold(0, (int sum, dynamic v) => sum + (v as int? ?? 0))}',
              ),
              pw.Text(
                'Average Rating: ${_calculateAverageRating(ratingDist).toStringAsFixed(1)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _calculateAverageRating(Map ratingDist) {
    double total = 0;
    int count = 0;
    for (int i = 1; i <= 10; i++) {
      final value = ratingDist[i.toString()];
      if (value != null) {
        total += i * (value as num);
        count += (value).toInt();
      }
    }
    return count > 0 ? total / count : 0;
  }

  static PdfColor _getRatingPdfColor(int rating) {
    if (rating >= 8) return PdfColors.green;
    if (rating >= 5) return PdfColors.orange;
    return PdfColors.red;
  }

  static pw.Widget _buildSuggestionsCard(List suggestions) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey100,
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Top Suggestions/Problems',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),
          ...suggestions
              .map(
                (s) => pw.Container(
                  padding: pw.EdgeInsets.only(left: 8.0, top: 4.0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontSize: 16)),
                      pw.Expanded(child: pw.Text(s)),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildParticipantsCard(List participants) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Participants',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '#',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Name',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Email',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...participants
                  .map(
                    (p) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            (participants.indexOf(p) + 1).toString(),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(p['name'] ?? 'Unknown Participant'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(p['email'] ?? 'No email provided'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }
}
