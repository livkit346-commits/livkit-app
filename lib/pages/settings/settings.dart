import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import '../../services/auth_service.dart';

import 'privacy_page.dart';
import 'security_page.dart';
import 'my_live_streams.dart';
import 'gift_and_earnings_page.dart';
import 'subscription_page.dart';
import 'notification.dart';
import 'language_page.dart';
import 'appearance_page.dart';
import 'help_center_page.dart';
import 'about_page.dart';
import '../auth/login_page.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/package_fonts.dart'; // Just using standard TextStyle if GoogleFonts isn't imported everywhere, actually let's just use TextStyle for now but use AppColors.

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _loading = false;

  String _displayName = "";
  String _username = "";
  String? _avatarUrl;
  String _referralCode = "";
  int _totalReferrals = 0;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final data = await _authService.fetchUserData();

      final profile = data["profile"] ?? {};

      setState(() {
        _displayName = profile["display_name"] ?? "";
        _username = data["username"] ?? "";
        _avatarUrl = profile["avatar"];
        _referralCode = data["referral_code"] ?? "";
        _totalReferrals = data["total_referrals"] ?? 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }

    setState(() => _loading = false);
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _profileHeader(),

                const SizedBox(height: 25),

                _section(
                  title: "Account",
                  items: [
                    _item(Icons.person, "Edit Profile"),
                    _item(Icons.lock, "Privacy"),
                    _item(Icons.security, "Security"),
                  ],
                ),

                _section(
                  title: "Live & Monetization",
                  items: [
                    _item(Icons.live_tv, "My Live Streams"),
                    _item(Icons.card_giftcard, "Gifts & Earnings"),
                    _item(Icons.subscriptions, "Subscriptions"),
                  ],
                ),

                _referralSection(),

                _section(
                  title: "Settings",
                  items: [
                    _item(Icons.notifications, "Notifications"),
                    _item(Icons.language, "Language"),
                  /*  _item(Icons.dark_mode, "Appearance"), */
                  ],
                ),

                _section(
                  title: "Support",
                  items: [
                    _item(Icons.help_outline, "Help Center"),
                    _item(Icons.info_outline, "About"),
                    _item(Icons.logout, "Log Out", danger: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // 🔹 Profile Header
  Widget _profileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white24,
          backgroundImage: _avatarUrl != null
              ? NetworkImage(_avatarUrl!)
              : null,
          child: _avatarUrl == null
              ? const Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayName.isNotEmpty ? _displayName : "No name",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _username.isNotEmpty ? "@$_username" : "",
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }


  // 🔹 Section Widget
  Widget _section({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // 🔹 Referral Section (Matches Web Full Function)
  Widget _referralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "REFERRAL",
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your referral code",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _referralCode.isNotEmpty ? _referralCode : "NOT GENERATED",
                        style: const TextStyle(
                          color: Color(0xFFFF0050),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: _referralCode.isNotEmpty ? () {
                      // Implement Copy to Clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Referral code copied!")),
                      );
                    } : null,
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                    label: const Text("Copy", style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Share this code. You earn USD rewards when friends subscribe! 🎉",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement Generate Referral Code API call
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Generating Referral Code...")),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(_referralCode.isNotEmpty ? "Regenerate Code" : "Generate Referral Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0050),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_totalReferrals > 0) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    "🏆 You've referred $_totalReferrals user${_totalReferrals == 1 ? '' : 's'}!",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // 🔹 Option Item
  Widget _item(IconData icon, String label, {bool danger = false}) {
    return InkWell(
      onTap: () {
        if (label == "Edit Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
        }

        if (label == "Privacy") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPage()),
          );
        }

        if (label == "Security") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecurityPage()),
          );
        }

        if (label == "My Live Streams") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyLiveStreamsPage()),
          );
        }
        if (label == "Gifts & Earnings") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GiftsEarningsPage()),
          );
        }
        if (label == "Subscriptions") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
          );
        }
        if (label == "Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          );
        }
        if (label == "Language") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LanguagePage()),
          );
        }

        if (label == "Appearance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppearancePage()),
          );
        }
        if (label == "Help Center") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpCenterPage()),
          );
        }
        if (label == "About") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPage()),
          );
        }

        if (label == "Log Out") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnimatedLoginPage()),
          );
        }
        // You can add navigation for other items later
      },
      splashColor: Colors.white24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? Colors.redAccent : AppColors.primary,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: danger ? Colors.redAccent : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

}
