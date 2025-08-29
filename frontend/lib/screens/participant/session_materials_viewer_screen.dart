import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class SessionMaterialsViewer extends StatelessWidget {
  final int sessionId;
  const SessionMaterialsViewer({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getSessionMaterials(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final materials = snapshot.data!;
        if (materials.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No resource materials shared for this session.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Resource Materials',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            ...materials.map((mat) {
              final isFile = mat['file'] != null;
              final isUrl =
                  mat['url'] != null && mat['url'].toString().isNotEmpty;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading:
                      isFile
                          ? const Icon(
                            Icons.insert_drive_file,
                            color: Colors.blue,
                          )
                          : const Icon(Icons.link, color: Colors.green),
                  title: Text(
                    mat['description'] ?? (isUrl ? mat['url'] : 'Material'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: isUrl ? Text(mat['url']) : null,
                  onTap:
                      isUrl
                          ? () async {
                            final url = Uri.parse(mat['url']);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          }
                          : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
