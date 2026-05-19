import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'quiz_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final db = FirebaseDatabase.instance.ref();
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final videoCtrl = TextEditingController();
  String category = 'beginner';

  Future<void> _addLesson() async {
    if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
    final lessonRef = db.child('lessons').push();
    await lessonRef.set({
      'title': titleCtrl.text,
      'category': category,
      'content': contentCtrl.text,
      'videoUrl': videoCtrl.text.isNotEmpty ? videoCtrl.text : null,
      'order': 0, // will reorder later
    });
    titleCtrl.clear();
    contentCtrl.clear();
    videoCtrl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lesson added!')));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Lesson',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: videoCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube Video URL (optional)',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField(
              value: category,
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Text('Intermediate'),
                ),
              ],
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addLesson,
              icon: const Icon(Icons.add),
              label: const Text('Add Lesson'),
            ),

            const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.quiz),
                label: const Text('Manage Quizzes'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizManagementScreen()),
                  );
                },
              ),
            const Divider(height: 40),
            const Text(
              'Quiz Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('(We will add quiz questions next)'),
          ],
        ),
      ),
    );
  }
}
