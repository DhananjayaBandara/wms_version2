import 'package:flutter/material.dart';
import 'package:frontend/models/question.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/app_footer.dart';
import 'package:intl/intl.dart';

class TrainerQuestionsScreen extends StatefulWidget {
  final int sessionId;
  final String sessionTitle;

  const TrainerQuestionsScreen({
    Key? key,
    required this.sessionId,
    required this.sessionTitle,
  }) : super(key: key);

  @override
  _TrainerQuestionsScreenState createState() => _TrainerQuestionsScreenState();
}

class _TrainerQuestionsScreenState extends State<TrainerQuestionsScreen> {
  bool _isLoading = true;
  List<Question> _questions = [];
  final Map<int, bool> _isMarkingAsAnswered = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await ApiService.getSessionQuestions(widget.sessionId);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleQuestionAnswered(Question question, bool? value) async {
    if (value == null || value == question.isAnswered) return;

    setState(() {
      _isMarkingAsAnswered[question.id] = true;
    });

    try {
      await ApiService.markQuestionAnswered(question.id, isAnswered: value);

      if (mounted) {
        // Update the local state immediately for better UX
        setState(() {
          final index = _questions.indexWhere((q) => q.id == question.id);
          if (index != -1) {
            _questions[index] = _questions[index].copyWith(
              isAnswered: value,
              answeredAt: value ? DateTime.now() : null,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Marked as answered' : 'Marked as unanswered',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update question: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAsAnswered[question.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions - ${widget.sessionTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuestions,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _questions.isEmpty
              ? const Center(child: Text('No questions yet.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return _buildQuestionCard(question);
                },
              ),
      bottomNavigationBar: const AppFooter(),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final isMarking = _isMarkingAsAnswered[question.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    question.participantName.isNotEmpty
                        ? question.participantName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.isAnonymous
                            ? 'Anonymous Participant'
                            : question.participantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatTime(question.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMarking) ...[
                  Checkbox(
                    value: question.isAnswered,
                    onChanged:
                        (value) => _toggleQuestionAnswered(question, value),
                    activeColor: Colors.green,
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(question.questionText, style: TextStyle(fontSize: 16)),
            if (question.answerText != null) ...{
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(question.answerText!),
                    Text(
                      'Answered on ${_formatDateTime(question.answeredAt ?? DateTime.now())}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            } else ...{
              const SizedBox(height: 16),
              const SizedBox(height: 8),
            },
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
