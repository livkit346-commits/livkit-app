import 'package:flutter/material.dart';
import '../../services/streaming_service.dart';
import '../../models/feed_item.dart';
import '../live/viewer_page.dart';
import '../live/feed_video.dart';
import 'global_search_page.dart';
import 'widgets/feed_action_bar.dart';
import 'widgets/feed_comment_overlay.dart';
import 'widgets/gift_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamingService _streamingService;
  late Future<List<FeedItem>> _feedFuture;
  int _currentIndex = 0;
  bool _isForYou = true;

  @override
  void initState() {
    super.initState();
    _streamingService = StreamingService();
    _feedFuture = _loadFeed();
  }

  Future<List<FeedItem>> _loadFeed() async {
    final data = await _streamingService.fetchHomeFeed();
    final List<FeedItem> items = [];

    if (data["live_streams"] != null) {
      for (final stream in data["live_streams"]) {
        items.add(FeedItem.fromStream(stream));
      }
    }

    if (data["fallbacks"] != null) {
      for (final video in data["fallbacks"]) {
        items.add(FeedItem.fromFallback(video));
      }
    }

    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _feedFuture = _loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 📄 FEED CONTENT
          RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<FeedItem>>(
              future: _feedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF0050)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No content available", style: TextStyle(color: Colors.white)));
                }

                final feed = snapshot.data!;

                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: feed.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return _FeedTile(
                      item: feed[index],
                      isActive: index == _currentIndex,
                    );
                  },
                );
              },
            ),
          ),

          /// 📍 TOP TABS (Following | For You)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TopTab(
                  label: "Following",
                  isActive: !_isForYou,
                  onTap: () => setState(() => _isForYou = false),
                ),
                const SizedBox(width: 20),
                _TopTab(
                  label: "For You",
                  isActive: _isForYou,
                  onTap: () => setState(() => _isForYou = true),
                ),
              ],
            ),
          ),

          /// 🔍 SEARCH ICON
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            right: 15,
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchPage())),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TopTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 2))],
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 30,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final FeedItem item;
  final bool isActive;

  const _FeedTile({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🎥 VIDEO CONTENT
        Positioned.fill(
          child: FeedVideo(
            type: isActive ? item.type : "fallback",
            videoUrl: item.videoUrl,
            channelName: item.channelName,
            agoraToken: item.agoraToken,
          ),
        ),

        /// 🌑 GRADIENT OVERLAY (Bottom shadowing for readability)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
        ),

        /// 👤 STREAMER INFO
        Positioned(
          bottom: 100,
          left: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.streamer ?? "Streamer",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0050),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text("Follow", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Live from the main stage! 🔥 #LivKit #LiveStream",
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
            ],
          ),
        ),

        /// 💬 COMMENT OVERLAY
        Positioned(
          bottom: 180,
          left: 15,
          child: SizedBox(
            height: 200,
            width: MediaQuery.of(context).size.width * 0.7,
            child: FeedCommentOverlay(
              comments: [
                CommentItem(username: "alex_pro", message: "Wow! This is amazing! 😍"),
                CommentItem(username: "stream_fan", message: "Love the vibes here!"),
                CommentItem(username: "gift_king", message: "Sending some support! 💎"),
              ],
            ),
          ),
        ),

        /// ⚡ ACTION BAR (Right Side)
        Positioned(
          bottom: 100,
          right: 15,
          child: FeedActionBar(
            likes: 1240,
            comments: 89,
            onLike: () {},
            onComment: () {},
            onShare: () {},
            onGift: () => GiftSheet.show(context),
          ),
        ),

        /// 🔴 LIVE BADGE
        if (item.type == "live")
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
      ],
    );
  }
}
