// screens/admin/admin_comments_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminCommentsScreen extends StatefulWidget {
  final int sessionId;
  final String sessionTitle;

  const AdminCommentsScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  _AdminCommentsScreenState createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends State<AdminCommentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await ApiService.getSessionAdminComments(
        widget.sessionId,
      );
      setState(() {
        _comments = comments;
        if (comments.isNotEmpty) {
          // Sort by creation date (newest first)
          comments.sort(
            (a, b) => DateTime.parse(
              b['created_at'],
            ).compareTo(DateTime.parse(a['created_at'])),
          );
          _commentController.text = comments[0]['comment'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading comments: $e')));
      }
    }
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final commentText = _commentController.text.trim();

      if (_comments.isNotEmpty) {
        // Update existing comment
        await ApiService.updateAdminComment(
          sessionId: widget.sessionId,
          comment: commentText,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment updated successfully!')),
          );
        }
      } else {
        // Create new comment
        await ApiService.submitAdminComment(
          sessionId: widget.sessionId,
          comment: commentText,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment submitted successfully!')),
          );
        }
      }

      // Refresh comments
      if (mounted) {
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Comments - ${widget.sessionTitle}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Comments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _commentController,
                                maxLines: 10,
                                decoration: InputDecoration(
                                  hintText: 'Enter your comments here...',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a comment';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_comments.isNotEmpty) ...[
                                const Text(
                                  'Comment History:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._comments.map(
                                  (comment) => Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: ListTile(
                                      title: Text(comment['comment'] ?? ''),
                                      subtitle: Text(
                                        _formatDate(comment['created_at']),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      dense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Submit Comment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
