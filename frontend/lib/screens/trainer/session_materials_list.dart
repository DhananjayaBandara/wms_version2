import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SessionMaterialsList extends StatelessWidget {
  final int sessionId;
  final VoidCallback onMaterialRemoved;
  const SessionMaterialsList({
    required this.sessionId,
    required this.onMaterialRemoved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getSessionMaterials(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final materials = snapshot.data!;
        if (materials.isEmpty) return Text('No materials uploaded yet.');
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: materials.length,
          itemBuilder: (context, idx) {
            final mat = materials[idx];
            return ListTile(
              leading:
                  mat['file'] != null
                      ? Icon(Icons.insert_drive_file, color: Colors.blue)
                      : Icon(Icons.link, color: Colors.green),
              title: Text(mat['description'] ?? mat['url'] ?? 'Material'),
              subtitle: mat['url'] != null ? Text(mat['url']) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mat['file'] != null)
                    IconButton(
                      icon: Icon(Icons.download),
                      onPressed: () {
                        // Implement file download/open logic
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: Text('Remove Material'),
                              content: Text(
                                'Are you sure you want to remove this material?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Remove'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        final success = await ApiService.deleteSessionMaterial(
                          mat['id'],
                        );
                        if (success) {
                          onMaterialRemoved();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Material removed')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to remove material'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              onTap:
                  mat['url'] != null
                      ? () async {
                        // Use url_launcher to open the link
                      }
                      : null,
            );
          },
        );
      },
    );
  }
}
