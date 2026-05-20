import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../theme/colors.dart';
import 'quiz_screen.dart';

class LessonDetailScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson['title'] ?? 'Lesson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson['content'] ?? 'No content.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (lesson['videoUrl'] != null &&
                        lesson['videoUrl'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildVideoPlayer(lesson['videoUrl']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Take Quiz button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.quiz),
                label: const Text('Take Quiz'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(lessonId: lesson['id']),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    // Safely extract the YouTube video ID
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      // If the URL isn't a valid YouTube link, fallback to showing a text link
      return Row(
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Video: $videoUrl',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }

    // Create the YouTube player controller
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppColors.accent,
      progressColors: const ProgressBarColors(
        playedColor: AppColors.accent,
        handleColor: AppColors.accent,
      ),
    );
  }
}