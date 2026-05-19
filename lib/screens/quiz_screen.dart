import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
        title: Text(passed ? 'Congratulations!' : 'Try Again'),
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
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: Text('No questions available.')),
      );
    }

    final q = questions[current];
    return Scaffold(
      appBar: AppBar(title: Text('Quiz (${current + 1}/${questions.length})')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q['question'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(q['options'].length, (index) {
              return ListTile(
                title: Text(q['options'][index] ?? ''),
                leading: Radio<int>(
                  value: index,
                  groupValue: null,
                  onChanged: (_) => _answer(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}