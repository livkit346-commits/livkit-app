import 'package:flutter/material.dart';

class FeedActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onGift;
  final int likes;
  final int comments;

  const FeedActionBar({
    super.key,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onGift,
    this.likes = 0,
    this.comments = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.favorite,
          label: likes.toString(),
          onTap: onLike,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.chat_bubble,
          label: comments.toString(),
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.share,
          label: "Share",
          onTap: onShare,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.card_giftcard,
          label: "Gift",
          onTap: onGift,
          isSpecial: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSpecial;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
              border: Border.all(
                color: isSpecial ? const Color(0xFFFF0050) : Colors.white10,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSpecial ? const Color(0xFFFF0050) : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black87,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
