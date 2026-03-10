import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';

class RestaurantPickerScreen extends StatefulWidget {
  final Player player;

  const RestaurantPickerScreen({super.key, required this.player});

  @override
  State<RestaurantPickerScreen> createState() => _RestaurantPickerScreenState();
}

class _RestaurantPickerScreenState extends State<RestaurantPickerScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/json/restaurants.json');
    final data = json.decode(raw) as List<dynamic>;
    setState(() {
      _all = data.cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  int _tierFromPriceRange(String priceRange) => priceRange.length.clamp(1, 4);

  Color _tierColor(int tier) {
    switch (tier) {
      case 1: return const Color(0xFF2EC95C);
      case 2: return const Color(0xFF1565C0);
      case 3: return const Color(0xFFE67E22);
      case 4: return const Color(0xFFC0185A);
      default: return Colors.grey;
    }
  }

  String _tierLabel(int tier) {
    switch (tier) {
      case 1: return "Ucuz";
      case 2: return "Orta";
      case 3: return "Bahalı";
      case 4: return "Lüks";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final affordable = _all
        .where((r) => widget.player.money >= (r['cost_azn'] as int))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "RESTORAN SEÇ",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFC0185A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : affordable.isEmpty
              ? const Center(
                  child: Text(
                    "Heç bir restorana getmək üçün pulun yoxdur.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                )
              : ListView.builder(
                  itemCount: affordable.length,
                  itemBuilder: (ctx, i) {
                    final r = affordable[i];
                    final tier = _tierFromPriceRange(r['price_range'] as String);
                    final color = _tierColor(tier);
                    final cost = r['cost_azn'] as int;
                    return InkWell(
                      onTap: () => Navigator.pop(context, r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.restaurant, color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r['cuisine'] as String,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      tier,
                                      (_) => Icon(Icons.star, size: 11, color: color),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$cost AZN",
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: color),
                                ),
                                Text(
                                  _tierLabel(tier),
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
