import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class LessonDetailScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson['title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson['content'], style: const TextStyle(fontSize: 16)),
            if (lesson['videoUrl'] != null) ...[
              const SizedBox(height: 16),
              // We'll embed video later; for now just show link
              Text('Video: ${lesson['videoUrl']}'),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz),
              label: const Text('Take Quiz'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(lessonId: lesson['id']),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
