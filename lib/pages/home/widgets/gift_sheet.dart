import 'package:flutter/material.dart';

class GiftSheet extends StatelessWidget {
  const GiftSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const GiftSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gifts = [
      {'icon': '🌹', 'name': 'Rose', 'price': 1},
      {'icon': '🍦', 'name': 'Ice Cream', 'price': 5},
      {'icon': '💖', 'name': 'Heart', 'price': 10},
      {'icon': '💍', 'name': 'Ring', 'price': 50},
      {'icon': '🚗', 'name': 'Car', 'price': 100},
      {'icon': '🚀', 'name': 'Rocket', 'price': 500},
      {'icon': '🏰', 'name': 'Castle', 'price': 1000},
      {'icon': '🦁', 'name': 'Lion', 'price': 5000},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🏷️ HEADER
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Send Gift",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        "1,250",
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "RECHARGE",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 🎁 GIFT GRID
          SizedBox(
            height: 250,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gift['icon'] as String, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          gift['name'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              gift['price'].toString(),
                              style: const TextStyle(color: Colors.amber, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          /// 🚀 SEND BUTTON (Sleek footer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0050),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text("SEND GIFT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
