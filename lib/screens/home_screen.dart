import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'lessons_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseDatabase.instance.ref();
  int coins = 0;
  int completed = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    db.child('users/$uid').onValue.listen((event) {
      final data = event.snapshot.value as Map<String, dynamic>?;
      if (data == null) return;
      setState(() {
        coins = data['coins'] ?? 0;
        completed = data['completedLessons'] != null
            ? (data['completedLessons'] as List).length
            : 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex Learn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 32, color: Colors.amber),
                const SizedBox(width: 8),
                Text('$coins coins', style: const TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Lessons completed: $completed', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.book),
              label: const Text('View Lessons'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonsScreen())),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin Panel'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
            ),
          ],
        ),
      ),
    );
  }
}