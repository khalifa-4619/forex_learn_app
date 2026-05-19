import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizManagementScreen extends StatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  final db = FirebaseDatabase.instance.ref();

  // Stores lessons fetched from DB
  List<Map<String, dynamic>> lessons = [];

  // Selected lesson ID from dropdown
  String? selectedLessonId;

  // Text controllers for the question form
  final questionCtrl = TextEditingController();
  final option1Ctrl = TextEditingController();
  final option2Ctrl = TextEditingController();
  final option3Ctrl = TextEditingController();
  final option4Ctrl = TextEditingController();
  int correctIndex = 0; // default first option is correct

  // Loading states
  bool isLoadingLessons = false;
  bool isAddingQuestion = false;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() => isLoadingLessons = true);
    try {
      final snap = await db.child('lessons').once();
      final raw = snap.snapshot.value;
      if (raw != null) {
        final linkedMap = Map<String, dynamic>.from(raw as Map);
        lessons = linkedMap.entries.map((e) {
          final lesson = Map<String, dynamic>.from(e.value as Map);
          lesson['id'] = e.key;
          return lesson;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching lessons for quiz: $e');
    }
    setState(() => isLoadingLessons = false);
  }

  Future<void> _addQuestion() async {
    if (selectedLessonId == null) {
      _showMessage('Please select a lesson first');
      return;
    }
    if (questionCtrl.text.isEmpty ||
        option1Ctrl.text.isEmpty ||
        option2Ctrl.text.isEmpty ||
        option3Ctrl.text.isEmpty ||
        option4Ctrl.text.isEmpty) {
      _showMessage('Fill in the question and all 4 options');
      return;
    }

    setState(() => isAddingQuestion = true);

    // Build the question object
    final questionData = {
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
      // Push the question into the array under the lesson
      await db
          .child('quizzes/$selectedLessonId/questions')
          .push()
          .set(questionData);

      // Clear the form
      questionCtrl.clear();
      option1Ctrl.clear();
      option2Ctrl.clear();
      option3Ctrl.clear();
      option4Ctrl.clear();
      correctIndex = 0;
      _showMessage('Question added!');
    } catch (e) {
      _showMessage('Error: $e');
    }

    setState(() => isAddingQuestion = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isLoadingLessons
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson selector dropdown
                  DropdownButtonFormField<String>(
                    value: selectedLessonId,
                    decoration: const InputDecoration(labelText: 'Select Lesson'),
                    items: lessons.map((lesson) {
                      return DropdownMenuItem<String>(
                        value: lesson['id'] as String,
                        child: Text(lesson['title'] ?? 'No title'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedLessonId = val);
                    },
                    validator: (v) => v == null ? 'Select a lesson' : null,
                  ),
                  const SizedBox(height: 24),

                  // Question form
                  if (selectedLessonId != null) ...[
                    Text('Add New Question',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: questionCtrl,
                      decoration: InputDecoration(labelText: 'Question'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: option1Ctrl,
                      decoration: InputDecoration(labelText: 'Option 1'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: option2Ctrl,
                      decoration: InputDecoration(labelText: 'Option 2'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: option3Ctrl,
                      decoration: InputDecoration(labelText: 'Option 3'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: option4Ctrl,
                      decoration: InputDecoration(labelText: 'Option 4'),
                    ),
                    const SizedBox(height: 16),
                    Text('Correct Answer:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    // Dropdown to pick the correct option
                    DropdownButtonFormField<int>(
                      value: correctIndex,
                      decoration: InputDecoration(labelText: 'Correct Option'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Option 1')),
                        DropdownMenuItem(value: 1, child: Text('Option 2')),
                        DropdownMenuItem(value: 2, child: Text('Option 3')),
                        DropdownMenuItem(value: 3, child: Text('Option 4')),
                      ],
                      onChanged: (val) {
                        setState(() => correctIndex = val!);
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: isAddingQuestion
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add),
                      label: Text(isAddingQuestion ? 'Adding...' : 'Add Question'),
                      onPressed: isAddingQuestion ? null : _addQuestion,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}