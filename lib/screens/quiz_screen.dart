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
  bool alreadyPassed = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // 🔍 Check if user already passed this quiz
      final attemptSnap = await db
          .child('users/$userId/quizAttempts/${widget.lessonId}')
          .once();
      final attemptData = attemptSnap.snapshot.value;
      if (attemptData != null) {
        final attempt = Map<String, dynamic>.from(attemptData as Map);
        if (attempt['passed'] == true) {
          setState(() {
            alreadyPassed = true;
            isLoading = false;
          });
          return;
        }
      }

      // Load questions
      final snap =
          await db.child('quizzes/${widget.lessonId}/questions').once();
      final raw = snap.snapshot.value;

      if (raw == null) {
        setState(() {
          error = 'No questions added for this lesson yet.';
          isLoading = false;
        });
        return;
      }

      if (raw is List) {
        questions = raw.map((q) => Map<String, dynamic>.from(q as Map)).toList();
      } else if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        questions = map.entries.map((entry) {
          final q = Map<String, dynamic>.from(entry.value as Map);
          q['id'] = entry.key;
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

  void _finishQuiz() async {
    final passed = score >= (questions.length * 0.6).ceil();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Save attempt
    await db.child('users/$userId/quizAttempts/${widget.lessonId}').set({
      'passed': passed,
      'score': score,
    });

    if (passed) {
      // Read current coins, add 10, and write back
      final coinSnapshot = await db.child('users/$userId/coins').once();
      final currentCoins = coinSnapshot.snapshot.value as int? ?? 0;
      await db.child('users/$userId/coins').set(currentCoins + 10);

      // Update completedLessons as a proper list
      final lessonsSnapshot =
          await db.child('users/$userId/completedLessons').once();
      List<dynamic> completedList = [];
      final lessonsData = lessonsSnapshot.snapshot.value;
      if (lessonsData != null) {
        if (lessonsData is List) {
          completedList = lessonsData;
        } else if (lessonsData is Map) {
          completedList = (lessonsData as Map).values.toList();
        }
      }
      if (!completedList.contains(widget.lessonId)) {
        completedList.add(widget.lessonId);
      }
      await db.child('users/$userId/completedLessons').set(completedList);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'Congratulations! 🎉' : 'Keep Trying! 💪'),
        content: Text('You scored $score/${questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // If passed, go back two screens (lesson detail)
              // else just go back to lesson detail (one screen)
              if (passed) {
                Navigator.pop(context);
              }
              Navigator.pop(context);
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
    if (alreadyPassed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Completed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'You already passed this quiz!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Lesson'),
                ),
              ],
            ),
          ),
        ),
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
      appBar: AppBar(title: Text('Quiz (${current + 1}/${questions.length})')),
      body: Column(
        children: [
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
                  Text(q['question'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 20),
                  ...List.generate(q['options'].length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _answer(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.circle_outlined,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(q['options'][index] ?? '',
                                    style: const TextStyle(fontSize: 16)),
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