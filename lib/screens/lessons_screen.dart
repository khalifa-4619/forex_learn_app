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
  bool isLoading = true;

  Future<void> _fetchLessons() async {
    setState(() => isLoading = true);
    try {
      final snap = await db.once();
      // Convert from JavaScript LinkedMap to Dart Map<String, dynamic>
      final raw = snap.snapshot.value;
      if (raw != null) {
        final linkedMap = Map<String, dynamic>.from(raw as Map);
        _lessons = linkedMap.entries.map((e) {
          final lesson = Map<String, dynamic>.from(e.value as Map);
          lesson['id'] = e.key;
          return lesson;
        }).toList();
      } else {
        _lessons = [];
      }
    } catch (e) {
      debugPrint('Error fetching lessons: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  @override
  Widget build(BuildContext context) {
    final beginner = _lessons.where((l) => l['category'] == 'beginner').toList();
    final intermediate = _lessons.where((l) => l['category'] == 'intermediate').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Forex Lessons')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLessons,
              child: ListView(
                children: [
                  if (beginner.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Beginner',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    ...beginner.map((l) => Card(
                      child: ListTile(
                        title: Text(l['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l['category'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l))),
                      ),
                    )),
                  ],
                  if (intermediate.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Intermediate',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    ...intermediate.map((l) => Card(
                      child: ListTile(
                        title: Text(l['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l['category'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l))),
                      ),
                    )),
                  ],
                  if (_lessons.isEmpty && !isLoading)
                    const Center(child: Text('No lessons yet. Add some from Admin Panel.')),
                ],
              ),
            ),
    );
  }
}