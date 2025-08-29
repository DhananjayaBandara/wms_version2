import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import '../../services/api_service.dart';

class QRScanAttendanceScreen extends StatefulWidget {
  final int participantId;

  const QRScanAttendanceScreen({super.key, required this.participantId});

  @override
  State<QRScanAttendanceScreen> createState() => _QRScanAttendanceScreenState();
}

class _QRScanAttendanceScreenState extends State<QRScanAttendanceScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _attendanceMarked = false;
  String? _feedbackMessage;
  final TextEditingController _manualTokenController = TextEditingController();

  @override
  void dispose() {
    controller?.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_attendanceMarked) return;
      setState(() => _attendanceMarked = true);

      // Extract session token from QR code (assume it's in the URL as ?session_token=...)
      final uri = Uri.tryParse(scanData.code ?? '');
      final sessionToken = uri?.queryParameters['session_token'];
      if (sessionToken == null || sessionToken.isEmpty) {
        setState(() {
          _feedbackMessage = 'Invalid QR code: session token not found.';
        });
        controller.pauseCamera();
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context, _feedbackMessage);
        return;
      }

      final data = await ApiService.markAttendanceViaQR(
        sessionToken: sessionToken,
        participantId: widget.participantId,
      );
      setState(() {
        _feedbackMessage = data['message'] ?? 'Unknown response.';
      });
      controller.pauseCamera();
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context, _feedbackMessage);
    });
  }

  Widget _buildUnsupportedPlatformView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Scanning Not Supported',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              'QR code scanning is not supported on this platform.\n\n'
              'Please enter the session token manually:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _manualTokenController,
              decoration: const InputDecoration(
                labelText: 'Enter Session Token',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Submit Token'),
              onPressed: _submitManualToken,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitManualToken() async {
    final token = _manualTokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please enter a session token';
      });
      return;
    }
    _handleQRCode(token);
  }

  void _handleQRCode(String token) async {
    final data = await ApiService.markAttendanceViaQR(
      sessionToken: token,
      participantId: widget.participantId,
    );
    setState(() {
      _feedbackMessage = data['message'] ?? 'Unknown response.';
    });
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context, _feedbackMessage);
  }

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance'), elevation: 0),
      body:
          _isMobilePlatform
              ? Column(
                children: [
                  Expanded(
                    flex: 4,
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Theme.of(context).primaryColor,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: MediaQuery.of(context).size.width * 0.8,
                      ),
                    ),
                  ),
                  if (_feedbackMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _feedbackMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Or enter token manually:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _manualTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Session Token',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Submit Token'),
                      onPressed: _submitManualToken,
                    ),
                  ),
                ],
              )
              : _buildUnsupportedPlatformView(),
    );
  }
}
