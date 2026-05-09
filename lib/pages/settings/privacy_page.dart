import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isPrivateAccount = false;
  bool _allowComments = true;
  bool _allowDuet = true;
  bool _allowDownload = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await _authService.fetchUserData();
    if (data.containsKey("privacy_settings")) {
      final p = data["privacy_settings"];
      if (mounted) {
        setState(() {
          _isPrivateAccount = p["is_private_account"] ?? false;
          _allowComments = p["allow_comments"] ?? true;
          _allowDuet = p["allow_duet"] ?? true;
          _allowDownload = p["allow_download"] ?? true;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSetting(String field, bool value) async {
    setState(() {
      if (field == "is_private_account") _isPrivateAccount = value;
      if (field == "allow_comments") _allowComments = value;
      if (field == "allow_duet") _allowDuet = value;
      if (field == "allow_download") _allowDownload = value;
    });

    final success = await _authService.updateSettings(
      type: "privacy",
      field: field,
      value: value,
    );

    if (!success) {
      setState(() {
        if (field == "is_private_account") _isPrivateAccount = !value;
        if (field == "allow_comments") _allowComments = !value;
        if (field == "allow_duet") _allowDuet = !value;
        if (field == "allow_download") _allowDownload = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update setting")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Privacy",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white24))
        : FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 10),
                _buildSwitchItem(
                  "Private Account",
                  "Only people you approve can follow you",
                  _isPrivateAccount,
                  (val) => _toggleSetting("is_private_account", val),
                ),
                const SizedBox(height: 20),
                _buildSwitchItem(
                  "Allow Comments",
                  "Control who can comment on your videos",
                  _allowComments,
                  (val) => _toggleSetting("allow_comments", val),
                ),
                const SizedBox(height: 20),
                _buildSwitchItem(
                  "Allow Duet & Stitch",
                  "Others can remix your videos",
                  _allowDuet,
                  (val) => _toggleSetting("allow_duet", val),
                ),
                const SizedBox(height: 20),
                _buildSwitchItem(
                  "Allow Downloads",
                  "Others can download your videos",
                  _allowDownload,
                  (val) => _toggleSetting("allow_download", val),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Your privacy settings control who can see your content and interact with you.",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
