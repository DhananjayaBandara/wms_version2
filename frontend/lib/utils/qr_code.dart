import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class QrCodePreviewScreen extends StatelessWidget {
  final String sessionToken;
  final int sessionId;

  const QrCodePreviewScreen({
    super.key,
    required this.sessionToken,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final String attendanceUrl = QrCodePreviewScreen.attendanceQrUrl(
      sessionToken,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () => _downloadQRCodeAsPDF(attendanceUrl),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: attendanceUrl,
                version: QrVersions.auto,
                size: 250.0,
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan the QR Code to mark attendance',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              SelectableText(
                attendanceUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String attendanceQrUrl(String sessionToken) {
    final String baseUrl = ApiService.baseUrl;

    return '$baseUrl/mark_attendance_qr?session_token=$sessionToken';
  }

  void _downloadQRCodeAsPDF(String data) async {
    final pdf = pw.Document();

    final image = await QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    ).toImageData(200);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Scan to Mark Attendance'),
                pw.SizedBox(height: 10),
                pw.Image(pw.MemoryImage(image!.buffer.asUint8List())),
                pw.SizedBox(height: 10),
                pw.Text(data, style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
