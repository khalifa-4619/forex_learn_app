import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;
  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> questions = [];
  int current = 0;
  int score = 0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final snap = await db.child('quizzes/${widget.lessonId}/questions').once();
      final raw = snap.snapshot.value;

      if (raw == null) {
        setState(() {
          error = 'No questions added for this lesson yet.';
          isLoading = false;
        });
        return;
      }

      // Convert from LinkedMap (web) or List (native) to a proper list
      if (raw is List) {
        // Native (Android/iOS) returns a list
        questions = raw.map((q) => Map<String, dynamic>.from(q as Map)).toList();
      } else if (raw is Map) {
        // Web returns a map with keys
        final map = Map<String, dynamic>.from(raw);
        questions = map.entries.map((entry) {
          final q = Map<String, dynamic>.from(entry.value as Map);
          q['id'] = entry.key; // optional: keep the push ID
          return q;
        }).toList();
      } else {
        error = 'Unexpected data format.';
      }
    } catch (e) {
      error = 'Failed to load questions: $e';
    }
    setState(() => isLoading = false);
  }

  void _answer(int chosen) {
    if (chosen == questions[current]['correctIndex']) {
      score++;
    }
    if (current < questions.length - 1) {
      setState(() => current++);
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final passed = score >= (questions.length * 0.6).ceil(); // 60% to pass
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Save attempt
    db.child('users/$userId/quizAttempts/${widget.lessonId}').set({
      'passed': passed,
      'score': score,
    });

    if (passed) {
      // Award 10 coins
      db.child('users/$userId/coins').set(ServerValue.increment(10));
      // Mark lesson as completed
      db.child('users/$userId/completedLessons').push().set(widget.lessonId);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'Congratulations! 🎉' : 'Keep Trying! 💪'),
        content: Text('You scored $score/${questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to lesson detail
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available.')),
      );
    }

    final q = questions[current];
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz (${current + 1}/${questions.length})'),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: LinearProgressIndicator(
              value: (current + 1) / questions.length,
              backgroundColor: Colors.grey[300],
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q['question'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(q['options'].length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _answer(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q['options'][index] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}