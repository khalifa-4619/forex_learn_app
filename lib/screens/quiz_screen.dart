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

  @override
  void initState() {
    super.initState();
    db.child('quizzes/${widget.lessonId}/questions').once().then((snap) {
      final data = snap.snapshot.value as List<dynamic>?;
      if (data == null) return;
      setState(() {
        questions = data.map((q) => Map<String, dynamic>.from(q)).toList();
      });
    });
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
    final passed = score >= (questions.length * 0.6); // 60% pass
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // Save attempt
    db.child('users/$userId/quizAttempts/${widget.lessonId}').set({
      'passed': passed,
      'score': score,
    });
    if (passed) {
      // Award coins (10 coins per quiz pass)
      db.child('users/$userId/coins').set(ServerValue.increment(10));
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'Congratulations!' : 'Try Again'),
        content: Text('You scored $score/${questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // back to detail
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = questions[current];
    return Scaffold(
      appBar: AppBar(title: Text('Quiz (${current + 1}/${questions.length})')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q['question'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(q['options'].length, (index) {
              return ListTile(
                title: Text(q['options'][index]),
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
