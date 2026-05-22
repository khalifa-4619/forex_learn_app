import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class QuizManagementScreen extends StatefulWidget {
  final String lessonId;
  const QuizManagementScreen({super.key, required this.lessonId});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  final db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  // Form controllers
  final questionCtrl = TextEditingController();
  final option1Ctrl = TextEditingController();
  final option2Ctrl = TextEditingController();
  final option3Ctrl = TextEditingController();
  final option4Ctrl = TextEditingController();
  int correctIndex = 0;
  String? editingQuestionId;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => isLoading = true);
    try {
      final snap = await db.child('quizzes/${widget.lessonId}/questions').once();
      final raw = snap.snapshot.value;
      if (raw != null && raw is Map) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = map.entries.map((e) {
          final q = Map<String, dynamic>.from(e.value as Map);
          q['id'] = e.key;
          return q;
        }).toList();
        setState(() => questions = list);
      } else {
        setState(() => questions = []);
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveQuestion() async {
    if (questionCtrl.text.isEmpty ||
        option1Ctrl.text.isEmpty ||
        option2Ctrl.text.isEmpty ||
        option3Ctrl.text.isEmpty ||
        option4Ctrl.text.isEmpty) {
      _showMessage('All fields are required');
      return;
    }

    final qData = {
      'question': questionCtrl.text.trim(),
      'options': [
        option1Ctrl.text.trim(),
        option2Ctrl.text.trim(),
        option3Ctrl.text.trim(),
        option4Ctrl.text.trim(),
      ],
      'correctIndex': correctIndex,
    };

    try {
      if (editingQuestionId == null) {
        await db.child('quizzes/${widget.lessonId}/questions').push().set(qData);
      } else {
        await db.child('quizzes/${widget.lessonId}/questions/$editingQuestionId').update(qData);
      }
      _clearForm();
      _fetchQuestions();
      _showMessage(editingQuestionId == null ? 'Question added!' : 'Question updated!');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  void _editQuestion(Map<String, dynamic> q) {
    setState(() {
      editingQuestionId = q['id'];
      questionCtrl.text = q['question'] ?? '';
      final options = q['options'] as List? ?? [];
      option1Ctrl.text = options.isNotEmpty ? options[0] ?? '' : '';
      option2Ctrl.text = options.length > 1 ? options[1] ?? '' : '';
      option3Ctrl.text = options.length > 2 ? options[2] ?? '' : '';
      option4Ctrl.text = options.length > 3 ? options[3] ?? '' : '';
      correctIndex = q['correctIndex'] ?? 0;
    });
  }

  void _clearForm() {
    questionCtrl.clear();
    option1Ctrl.clear();
    option2Ctrl.clear();
    option3Ctrl.clear();
    option4Ctrl.clear();
    correctIndex = 0;
    editingQuestionId = null;
  }

  Future<void> _deleteQuestion(String questionId) async {
    await db.child('quizzes/${widget.lessonId}/questions/$questionId').remove();
    _fetchQuestions();
    _showMessage('Question deleted');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    questionCtrl.dispose();
    option1Ctrl.dispose();
    option2Ctrl.dispose();
    option3Ctrl.dispose();
    option4Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Management')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add/Edit Question Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editingQuestionId == null ? 'Add New Question' : 'Edit Question',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: questionCtrl,
                            decoration: const InputDecoration(labelText: 'Question'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: option1Ctrl,
                            decoration: const InputDecoration(labelText: 'Option 1'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: option2Ctrl,
                            decoration: const InputDecoration(labelText: 'Option 2'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: option3Ctrl,
                            decoration: const InputDecoration(labelText: 'Option 3'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: option4Ctrl,
                            decoration: const InputDecoration(labelText: 'Option 4'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: correctIndex,
                            decoration: const InputDecoration(labelText: 'Correct Option'),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Option 1')),
                              DropdownMenuItem(value: 1, child: Text('Option 2')),
                              DropdownMenuItem(value: 2, child: Text('Option 3')),
                              DropdownMenuItem(value: 3, child: Text('Option 4')),
                            ],
                            onChanged: (v) => setState(() => correctIndex = v!),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveQuestion,
                                icon: Icon(editingQuestionId == null ? Icons.add : Icons.save),
                                label: Text(editingQuestionId == null ? 'Add Question' : 'Update Question'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(0, 50),
                                ),
                              ),
                              if (editingQuestionId != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _clearForm,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Existing Questions List
                  const Text(
                    'Existing Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (questions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No questions added yet.'),
                    )
                  else
                    ...questions.map((q) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(q['question'] ?? 'No question'),
                            subtitle: Text(
                              'Correct: ${(q['options'] as List?)?[q['correctIndex'] ?? 0] ?? ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editQuestion(q),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteQuestion(q['id']),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}