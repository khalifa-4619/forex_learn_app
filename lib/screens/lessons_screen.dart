import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final db = FirebaseDatabase.instance.ref().child('lessons');
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    db.onValue.listen((event) {
      final data = event.snapshot.value as Map<String, dynamic>?;
      if (data == null) return;
      setState(() {
        _lessons = data.entries.map((e) {
          final lesson = Map<String, dynamic>.from(e.value);
          lesson['id'] = e.key;
          return lesson;
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final beginner = _lessons.where((l) => l['category'] == 'beginner').toList();
    final intermediate = _lessons.where((l) => l['category'] == 'intermediate').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Forex Lessons')),
      body: _lessons.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (beginner.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Beginner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  ...beginner.map((lesson) => ListTile(
                        title: Text(lesson['title']),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(lesson: lesson),
                          ),
                        ),
                      )),
                ],
                if (intermediate.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Intermediate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  ...intermediate.map((lesson) => ListTile(
                        title: Text(lesson['title']),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(lesson: lesson),
                          ),
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}
