import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class CoinWalletPage extends StatefulWidget {
  const CoinWalletPage({super.key});

  @override
  State<CoinWalletPage> createState() => _CoinWalletPageState();
}

class _CoinWalletPageState extends State<CoinWalletPage> {
  final AuthService _authService = AuthService();
  String? _accessToken;
  bool _isLoading = true;
  List<dynamic> _packages = [];
  int _balance = 0;
  String _usdBalance = "0.00";
  String _earnings = "0.00";
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _accessToken = await _authService.getAccessToken();
    if (_accessToken != null) {
      final userData = await _authService.fetchUserData();
      if (mounted) {
        setState(() {
          _usdBalance = userData["usd_balance"]?.toString() ?? "0.00";
          _earnings = userData["withdrawable_balance"]?.toString() ?? "0.00";
          _balance = userData["coin_balance"] is int 
              ? userData["coin_balance"] 
              : int.tryParse(userData["coin_balance"]?.toString() ?? "0") ?? 0;
          _transactions = userData["transactions"] ?? [];
        });
      }
      await _fetchPackages();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchPackages() async {
    try {
      final response = await http.get(
        Uri.parse("https://livkit.onrender.com/api/payments/coins/"),
        headers: {"Authorization": "Bearer $_accessToken"},
      );
      if (response.statusCode == 200) {
        setState(() {
          _packages = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buyPackage(int packageId) async {
    if (_accessToken == null) return;
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final response = await http.post(
        Uri.parse("https://livkit.onrender.com/api/payments/coins/buy/"),
        headers: {
          "Authorization": "Bearer $_accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"package_id": packageId}),
      );
      
      Navigator.pop(context); // close loader
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _balance = data['new_balance'] ?? _balance;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Purchase successful!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to purchase package.")),
        );
      }
    } catch (e) {
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match web's pure black
      appBar: AppBar(
        title: const Text("My Wallet", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Cards Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // USD Balance (Primary Card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF0050), Color(0xFF7C0AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0050).withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("USD BALANCE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Text("\$$_usdBalance", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(Icons.account_balance_wallet, color: Colors.white24, size: 40),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Coins and Earnings Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("COINS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Text("$_balance", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const Positioned(
                                right: -4,
                                top: -4,
                                child: Icon(Icons.toll, color: Colors.white24, size: 36),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("EARNINGS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Text("\$$_earnings", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const Positioned(
                                right: -4,
                                top: -4,
                                child: Icon(Icons.trending_up, color: Colors.white24, size: 36),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Transaction History Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "TRANSACTION HISTORY",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dynamic Transaction List or Empty State
            _transactions.isEmpty 
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white.withOpacity(0.3), size: 52),
                        const SizedBox(height: 12),
                        Text(
                          "No transactions yet.\nRefer a friend to earn your first reward!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final isWithdrawal = tx['type'] == 'withdrawal';
                    return ListTile(
                      leading: Icon(
                        isWithdrawal ? Icons.arrow_outward : Icons.arrow_downward, 
                        color: isWithdrawal ? Colors.redAccent : Colors.greenAccent
                      ),
                      title: Text(
                        tx['description'] ?? 'Transaction', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
                      ),
                      subtitle: Text(
                        tx['created_at']?.split('T')[0] ?? '', 
                        style: const TextStyle(color: Colors.white54, fontSize: 12)
                      ),
                      trailing: Text(
                        "${isWithdrawal ? '-' : '+'}\$${tx['amount_usd']}", 
                        style: TextStyle(
                          color: isWithdrawal ? Colors.redAccent : Colors.greenAccent, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        )
                      ),
                    );
                  },
                ),
            
            // Note: Package list to buy coins could be placed here or in a separate tab/modal
            // depending on exact UX matching, but for now we perfectly replicate wallet.html
          ],
        ),
      ),
    );
  }
}
