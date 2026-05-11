import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../settings/settings.dart';
import '../../services/auth_service.dart';
import 'coin_wallet_page.dart';


class SelfProfileScreen extends StatefulWidget {
  const SelfProfileScreen({super.key});

  @override
  State<SelfProfileScreen> createState() => _SelfProfileScreenState();
}

class _SelfProfileScreenState extends State<SelfProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final AuthService _authService = AuthService();

  bool _loading = true;

  String? _avatarUrl;
  String _displayName = "";
  String _username = "";
  String _bio = "";

  // mock for now (later backend)
  int postsCount = 0;
  int followersCount = 0;
  int followingCount = 0;


  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    _loadProfile();
  }


  Future<void> _loadProfile() async {
    try {
      final data = await _authService.fetchUserData();
      final profile = data["profile"] ?? {};

      setState(() {
        _username = data["username"]?.isNotEmpty == true ? data["username"] : "User";
        _displayName = profile["display_name"]?.isNotEmpty == true ? profile["display_name"] : "New User";
        _bio = profile["bio"] ?? "";
        _avatarUrl = profile["avatar"];

        // live values from Django backend
        postsCount = data["posts_count"] ?? 0;
        followersCount = data["followers_count"] ?? 0;
        followingCount = data["following_count"] ?? 0;

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
  }



  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(



          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // 🔝 TOP BAR + PROFILE HEADER (SCROLLS AWAY)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Cover Image & Top Actions
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Cover Image Background
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade900, Colors.black],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Top Actions
                            Positioned(
                              top: 8,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.account_balance_wallet, color: Colors.amber),
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinWalletPage())),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.settings, color: Colors.white),
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Settings())),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Overlapping Avatar
                            Positioned(
                              bottom: -40,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                    child: _avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 50),

                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "@$_username",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        // Action Buttons (Edit Profile / Share)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Settings())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text("Edit Profile"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Profile link copied!")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.ios_share, size: 18),
                              label: const Text("Share Profile"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Stats Row
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statItem(followersCount.toString(), "Followers"),
                              _divider(),
                              _statItem(followingCount.toString(), "Following"),
                              _divider(),
                              _statItem(postsCount.toString(), "Posts"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),


                  SliverToBoxAdapter(
                    child: _bio.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Text(
                                  _bio,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  


                  // 📑 STICKY TAB BAR
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 2,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white38,
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on)),
                          Tab(icon: Icon(Icons.person_pin_outlined)),
                        ],
                      ),
                    ),
                  ),
                ];
              },

              // 🧩 TAB CONTENT
              body: TabBarView(
                controller: _tabController,
                children: [
                  // 🟦 POSTS GRID
                  GridView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: 12,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.image,
                            color: Colors.white54),
                      );
                    },
                  ),

                  // 🏷️ TAGGED
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.person_pin_outlined,
                            size: 60, color: Colors.white24),
                        SizedBox(height: 10),
                        Text(
                          "No tagged posts yet",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 STAT ITEM
  static Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white12,
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
