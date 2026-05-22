import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'quiz_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> lessons = [];
  bool isLoading = true;

  // Form controllers for adding/editing
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final videoCtrl = TextEditingController();
  String category = 'beginner';
  String? editingLessonId;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() => isLoading = true);
    try {
      final snap = await db.child('lessons').once();
      final raw = snap.snapshot.value;
      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = map.entries.map((e) {
          final lesson = Map<String, dynamic>.from(e.value as Map);
          lesson['id'] = e.key;
          return lesson;
        }).toList();
        // Sort by order or title
        list.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
        setState(() => lessons = list);
      } else {
        setState(() => lessons = []);
      }
    } catch (e) {
      debugPrint('Error fetching lessons: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveLesson() async {
    if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) {
      _showMessage('Title and content are required');
      return;
    }

    final lessonData = {
      'title': titleCtrl.text.trim(),
      'category': category,
      'content': contentCtrl.text.trim(),
      'videoUrl': videoCtrl.text.trim().isNotEmpty ? videoCtrl.text.trim() : null,
      'order': lessons.length, // simple ordering
    };

    try {
      if (editingLessonId == null) {
        // Add new
        await db.child('lessons').push().set(lessonData);
      } else {
        // Update existing
        await db.child('lessons/$editingLessonId').update(lessonData);
      }
      _clearForm();
      _fetchLessons();
      _showMessage(editingLessonId == null ? 'Lesson added!' : 'Lesson updated!');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  void _editLesson(Map<String, dynamic> lesson) {
    setState(() {
      editingLessonId = lesson['id'];
      titleCtrl.text = lesson['title'] ?? '';
      contentCtrl.text = lesson['content'] ?? '';
      videoCtrl.text = lesson['videoUrl'] ?? '';
      category = lesson['category'] ?? 'beginner';
    });
  }

  void _clearForm() {
    titleCtrl.clear();
    contentCtrl.clear();
    videoCtrl.clear();
    category = 'beginner';
    editingLessonId = null;
  }

  Future<void> _deleteLesson(String lessonId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text('This will also delete all associated quiz questions. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await db.child('lessons/$lessonId').remove();
        await db.child('quizzes/$lessonId').remove(); // delete associated quiz
        _fetchLessons();
        _showMessage('Lesson deleted');
      } catch (e) {
        _showMessage('Error deleting: $e');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add / Edit Lesson Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editingLessonId == null ? 'Add New Lesson' : 'Edit Lesson',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(labelText: 'Title'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: contentCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(labelText: 'Content'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: videoCtrl,
                            decoration: const InputDecoration(labelText: 'YouTube URL (optional)'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: const [
                              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                              DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                            ],
                            onChanged: (v) => setState(() => category = v!),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveLesson,
                                icon: Icon(editingLessonId == null ? Icons.add : Icons.save),
                                label: Text(editingLessonId == null ? 'Add Lesson' : 'Update Lesson'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(0, 50),   // override global infinity width
                                ),
                              ),
                              if (editingLessonId != null) ...[
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
                  // Existing Lessons List
                  const Text(
                    'Existing Lessons',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (lessons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No lessons added yet.'),
                    )
                  else
                    ...lessons.map((lesson) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(lesson['title'] ?? 'No title'),
                            subtitle: Text(lesson['category'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.quiz, color: AppColors.primary),
                                  tooltip: 'Manage Quizzes',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuizManagementScreen(lessonId: lesson['id']),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editLesson(lesson),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteLesson(lesson['id']),
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