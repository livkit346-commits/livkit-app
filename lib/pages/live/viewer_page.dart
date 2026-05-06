import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../config/agora_config.dart';
import '../../services/streaming_service.dart';
import '../../widgets/live_action.dart';
import '../../widgets/tiktok_comments.dart';
import 'package:share_plus/share_plus.dart';
import '../home/widgets/gift_sheet.dart';

class ViewerPage extends StatefulWidget {
  final String streamId;
  final String title;
  final String feedType; // live | grace

  const ViewerPage({
    super.key,
    required this.streamId,
    required this.title,
    required this.feedType,
  });

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage>
    with WidgetsBindingObserver {
  final TextEditingController _commentController = TextEditingController();
  final TikTokCommentsController commentsController =
      TikTokCommentsController();

  late final StreamingService _streamingService;
  late RtcEngine _engine;
  int? _remoteUid;
  bool _engineReady = false;

  Timer? _heartbeatTimer;
  bool _joined = false;

  String? _channelName;
  String? _agoraToken;
  int _heartbeatInterval = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _streamingService =
        StreamingService();

    // ONLY join if this is a live stream
    if (widget.feedType == "live") {
      _joinStream();
    }
  }


  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    await _engine.enableVideo(); // ✅ ADD THIS

    await _engine.setClientRole(
      role: ClientRoleType.clientRoleAudience,
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.joinChannel(
      token: _agoraToken!,
      channelId: _channelName!,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );

    setState(() {
      _engineReady = true;
    });
  }


  Future<void> _joinStream() async {
    try {
      final data = await _streamingService.joinLiveStream(
        streamId: widget.streamId,
      );

      if (!mounted) return;

      setState(() {
        _channelName = data["channel_name"];
        _agoraToken = data["agora_token"];
        _heartbeatInterval = data["heartbeat_interval"] ?? 10;
        _joined = true;
      });

      _startHeartbeat();
      await _initAgora(); // move this inside try
    } catch (_) {
      _showErrorAndExit("Failed to join stream");
    }
  }

  /// ❤️ HEARTBEAT
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatInterval),
      (_) async {
        try {
          await _streamingService.sendHeartbeat(
            streamId: widget.streamId,
          );
        } catch (_) {
          _showErrorAndExit("Connection lost");
        }
      },
    );
  }

  /// 🚪 LEAVE STREAM
  Future<void> _leaveStream() async {
    if (!_joined) return;

    _heartbeatTimer?.cancel();

    try {
      await _streamingService.leaveLiveStream(
        streamId: widget.streamId,
      );
    } catch (_) {}
  }

  /// 🛑 HANDLE BACKGROUND / APP CLOSE
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _leaveStream();
    }
  }

  void _showErrorAndExit(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.pop(context);
  }

  void _sendGift() async {
    try {
      await _streamingService.sendGift(streamId: widget.streamId, amount: 10);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sent 10 coins! 🎁")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send gift.")),
      );
    }
  }

  void _requestCoHost() async {
    try {
      // await _streamingService.requestCoHost(streamId: widget.streamId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Co-Host feature coming soon! 🎥")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not send Co-Host request.")),
      );
    }
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    commentsController.addComment(text);
    _commentController.clear();
  }

  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();

    if (_joined) {
      _streamingService.leaveLiveStream(
        streamId: widget.streamId,
      );
    }

    _commentController.dispose();

    if (_engineReady) {
      try {
        _engine.leaveChannel();
        _engine.release();
      } catch (_) {}
    }

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isGrace = widget.feedType == "grace";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🎥 VIDEO PLACEHOLDER (Agora mounts here next step)
          _engineReady && _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: _channelName),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

          /// 👤 TOP INFO
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 15,
            right: 15,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "1.2k viewers",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0050),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Follow",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          /// 🎯 ACTIONS (using integrated bar)
          if (!isGrace)
            Positioned(
              right: 12,
              bottom: 120,
              child: Column(
                children: [
                  _actionIcon(Icons.add_moderator, "Sub"),
                  const SizedBox(height: 16),
                  _actionIcon(Icons.card_giftcard, "Gift", onTap: () {
                    GiftSheet.show(context);
                  }),
                  const SizedBox(height: 16),
                  _actionIcon(Icons.video_call, "Join"),
                  const SizedBox(height: 16),
                  _actionIcon(Icons.share, "Share", onTap: () {
                    Share.share('https://livkit.onrender.com/live/${widget.streamId}');
                  }),
                ],
              ),
            ),

          /// 💬 COMMENTS
          TikTokComments(controller: commentsController),

          /// ✍️ COMMENT INPUT
          if (!isGrace)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onSubmitted: (_) => _sendComment(),
                          decoration: const InputDecoration(
                            hintText: "Say something...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.emoji_emotions_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendComment,
                      child: const Icon(Icons.send_rounded, color: Color(0xFFFF0050), size: 28),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
