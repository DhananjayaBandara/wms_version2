import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UploadMaterialWidget extends StatefulWidget {
  final int sessionId;
  final int trainerId;
  final VoidCallback onUploadSuccess;

  const UploadMaterialWidget({
    required this.sessionId,
    required this.trainerId,
    required this.onUploadSuccess,
    super.key,
  });

  @override
  State<UploadMaterialWidget> createState() => _UploadMaterialWidgetState();
}

class _UploadMaterialWidgetState extends State<UploadMaterialWidget> {
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  bool _isUploading = false;

  Future<void> _upload() async {
    setState(() => _isUploading = true);
    final result = await ApiService.uploadSessionMaterial(
      sessionId: widget.sessionId,
      trainerId: widget.trainerId,
      url: _urlController.text.isNotEmpty ? _urlController.text : null,
      description: _descController.text,
    );
    setState(() => _isUploading = false);
    if (result['success'] == true) {
      _urlController.clear();
      _descController.clear();
      widget.onUploadSuccess();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Material uploaded!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to upload material')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(labelText: 'Resource URL (optional)'),
        ),
        TextField(
          controller: _descController,
          decoration: InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon:
              _isUploading
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(Icons.upload_file),
          label: Text('Upload Material'),
          onPressed: _isUploading ? null : _upload,
        ),
      ],
    );
  }
}
