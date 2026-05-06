import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/streaming_service.dart';
import '../../config/agora_config.dart';
import 'streamer_page.dart';

class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  RtcEngine? _engine;
  bool _isLoading = false;
  bool _isPrivate = false;
  bool _previewReady = false;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted) {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();
      
      if (mounted) {
        setState(() {
          _previewReady = true;
        });
      }
    }
  }

  Future<void> _startLive() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final streamingService = StreamingService();

    try {
      final response = await streamingService.createLiveStream(
        title: _titleController.text.trim().isEmpty
            ? "Untitled Live"
            : _titleController.text.trim(),
        isPrivate: _isPrivate,
        password: _isPrivate ? _passwordController.text.trim() : null,
      );

      final stream = response["stream"];

      if (_engine != null) {
        await _engine!.stopPreview();
        await _engine!.release();
        _engine = null;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StreamerPage(
            streamId: stream["id"],
            channelName: response["channel_name"],
            agoraToken: response["agora_token"],
            title: _titleController.text.trim().isEmpty
                ? "Live Now"
                : _titleController.text.trim(),
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to start live: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();
    _engine?.stopPreview();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎥 FULLSCREEN CAMERA PREVIEW
          if (_previewReady && _engine != null)
            SizedBox.expand(
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            )
          else
            const SizedBox.expand(child: Center(child: CircularProgressIndicator(color: Color(0xFFFF0050)))),

          // 🌑 DARK OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ───────── TOP BAR ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        "GO LIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.switch_camera_rounded, color: Colors.white, size: 28),
                        onPressed: () => _engine?.switchCamera(),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ───────── TITLE INPUT ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLength: 80,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        counterText: "",
                        hintText: "What are you doing today?",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ───────── OPTIONS ─────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Option(
                        onTap: () => setState(() => _isPrivate = !_isPrivate),
                        icon: _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                        label: _isPrivate ? "Private" : "Public",
                        color: _isPrivate ? const Color(0xFFFF0050) : Colors.white,
                      ),
                      const _Option(icon: Icons.auto_awesome, label: "Beauty"),
                      const _Option(icon: Icons.share_rounded, label: "Share"),
                      const _Option(icon: Icons.settings_rounded, label: "Settings"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ───────── GO LIVE BUTTON ─────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _isLoading ? null : _startLive,
                    child: Container(
                      width: 240,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0050), Color(0xFFD40042)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0050).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "GO LIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _Option({required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
