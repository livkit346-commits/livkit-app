import 'package:flutter/material.dart';

class FeedCommentOverlay extends StatelessWidget {
  final List<CommentItem> comments;

  const FeedCommentOverlay({super.key, required this.comments});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
          stops: [0.0, 0.2],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: comments.length,
        reverse: true, // Newest at bottom
        itemBuilder: (context, index) {
          final comment = comments[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: comment.avatarUrl != null 
                    ? NetworkImage(comment.avatarUrl!) 
                    : null,
                  child: comment.avatarUrl == null 
                    ? const Icon(Icons.person, size: 16) 
                    : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.username,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        comment.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CommentItem {
  final String username;
  final String message;
  final String? avatarUrl;

  CommentItem({
    required this.username,
    required this.message,
    this.avatarUrl,
  });
}
