import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/forgot_password_page.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Security settings state
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _twoFactorAuth = false;
  bool _securityAlerts = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await _authService.fetchUserData();
    if (data.containsKey("security_settings")) {
      final s = data["security_settings"];
      if (mounted) {
        setState(() {
          _twoFactorAuth = s["two_factor_auth"] ?? false;
          _securityAlerts = s["security_alerts"] ?? true;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSetting(String field, bool value) async {
    setState(() {
      if (field == "two_factor_auth") _twoFactorAuth = value;
      if (field == "security_alerts") _securityAlerts = value;
    });

    final success = await _authService.updateSettings(
      type: "security",
      field: field,
      value: value,
    );

    if (!success) {
      setState(() {
        if (field == "two_factor_auth") _twoFactorAuth = !value;
        if (field == "security_alerts") _securityAlerts = !value;
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

  // 🔹 Show "Coming Soon" Dialog
  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction, color: Colors.amber, size: 50),
                const SizedBox(height: 20),
                const Text(
                  "Coming Soon!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "This feature will be available in the next update.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Security",
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

                // Change Password
                _buildListItem(
                  Icons.lock_outline,
                  "Change Password",
                  "Update your account password",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPassword(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Two-Factor Authentication
                _buildSwitchItem(
                  "Two-Factor Authentication",
                  "Add an extra layer of security to your account",
                  _twoFactorAuth,
                  (val) => _toggleSetting("two_factor_auth", val),
                ),

                const SizedBox(height: 20),

                // Login Activity
                _buildListItem(
                  Icons.login,
                  "Login Activity",
                  "See devices where your account is logged in",
                  onTap: _showComingSoonDialog, // <-- Coming soon dialog
                ),

                const SizedBox(height: 20),

                // Authorized Devices
                _buildListItem(
                  Icons.devices,
                  "Authorized Devices",
                  "Manage devices that can access your account",
                  onTap: _showComingSoonDialog, // <-- Coming soon dialog
                ),

                const SizedBox(height: 20),

                // Security Alerts
                _buildSwitchItem(
                  "Security Alerts",
                  "Receive alerts about suspicious activity",
                  _securityAlerts,
                  (val) => _toggleSetting("security_alerts", val),
                ),

                const SizedBox(height: 30),

                // Footer info
                const Center(
                  child: Text(
                    "Keep your account secure by managing passwords, devices, and alerts.",
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

  // 🔹 Helper method for switch items
  Widget _buildSwitchItem(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
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
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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

  // 🔹 Helper method for clickable list items
  Widget _buildListItem(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.white24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
