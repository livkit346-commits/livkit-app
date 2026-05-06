import 'dart:convert';
import 'package:flutter/material.dart';
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
  int _balance = 0; // In a full prod app this would be fetched from a user/wallet endpoint

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _accessToken = await _authService.getAccessToken();
    if (_accessToken != null) {
      await _fetchPackages();
    } else {
      setState(() => _isLoading = false);
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Wallet", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withOpacity(0.05), height: 1),
        ),
      ),
      body: Column(
        children: [
          // 💳 BALANCE CARD
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0050), Color(0xFFD40042)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0050).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "MY BALANCE", 
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 42),
                    const SizedBox(width: 12),
                    Text(
                      "$_balance", 
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "≈ \$${(_balance / 100).toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "RECHARGE COINS",
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF0050)))
              : _packages.isEmpty 
                  ? const Center(child: Text("No packages available", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        final pkg = _packages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${pkg['coin_amount']} Coins", 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Get started with a quick boost", 
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF0050),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () => _buyPackage(pkg['id']),
                                child: Text(
                                  "\$${pkg['usd_price']}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold)
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                  ),
          ),
        ],
      ),
    );
  }
}
