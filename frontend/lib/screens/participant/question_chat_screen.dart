import 'package:flutter/material.dart';
import 'package:frontend/models/question.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/app_footer.dart';
import 'package:intl/intl.dart';

class QuestionChatScreen extends StatefulWidget {
  final int sessionId;
  final int participantId;

  const QuestionChatScreen({
    Key? key,
    required this.sessionId,
    required this.participantId,
  }) : super(key: key);

  @override
  _QuestionChatScreenState createState() => _QuestionChatScreenState();
}

class _QuestionChatScreenState extends State<QuestionChatScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAnonymous = false;
  List<Question> _questions = [];
  String _sessionTitle = 'Session Q&A';

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _loadQuestions();
  }

  Future<void> _loadSessionData() async {
    try {
      final sessions = await ApiService.getSessions();
      final session = sessions.firstWhere(
        (s) => s['id'] == widget.sessionId,
        orElse: () => {},
      );

      if (mounted && session.isNotEmpty) {
        setState(() {
          _sessionTitle = session['title'] ?? 'Session Q&A';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load session details: $e')),
        );
      }
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await ApiService.getSessionQuestions(widget.sessionId);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
        _scrollToBottom();
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

  Future<void> _submitQuestion() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.submitQuestion(
        sessionId: widget.sessionId,
        participantId: widget.participantId,
        questionText: questionText,
        isAnonymous: _isAnonymous,
      );

      _questionController.clear();
      await _loadQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit question: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionTitle),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuestions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _questions.isEmpty
                    ? const Center(
                      child: Text('No questions yet. Be the first to ask!'),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_questions[index]);
                      },
                    ),
          ),
          _buildInputArea(),
        ],
      ),
      bottomNavigationBar: AppFooter(),
    );
  }

  Widget _buildMessageBubble(Question question) {
    final isMe = question.participantId == widget.participantId;
    final isAnswered = question.isAnswered;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 40.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? (isAnswered
                            ? Colors.green.shade100
                            : Colors.blue.shade100)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color:
                      isAnswered ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      question.isAnonymous
                          ? 'Anonymous'
                          : question.participantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  const SizedBox(height: 4.0),
                  Text(question.questionText),
                  if (isAnswered && question.answerText != null) ...[
                    const Divider(height: 16.0, thickness: 1.0),
                    Text(
                      'Answer: ${question.answerText}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 4.0),
                  Text(
                    _formatTime(question.createdAt),
                    style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8.0),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Type your question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) => _submitQuestion(),
                ),
              ),
              const SizedBox(width: 8.0),
              _isSubmitting
                  ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                  : IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _submitQuestion,
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
