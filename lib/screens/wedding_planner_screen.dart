import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';

class WeddingPlannerScreen extends StatefulWidget {
  final Player player;
  final SchoolMate partner;

  const WeddingPlannerScreen({
    super.key,
    required this.player,
    required this.partner,
  });

  @override
  State<WeddingPlannerScreen> createState() => _WeddingPlannerScreenState();
}

class _WeddingPlannerScreenState extends State<WeddingPlannerScreen> {
  int _step = 0; // 0=venue, 1=guests, 2=date, 3=summary

  List<Map<String, dynamic>> _venues = [];
  List<Map<String, dynamic>> _guestTiers = [];
  bool _loading = true;

  int _selectedVenueIdx = 0;
  int _selectedGuestTierIdx = 0;
  int _yearsAhead = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/json/wedding_config.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    setState(() {
      _venues = (data['venues'] as List).cast<Map<String, dynamic>>();
      _guestTiers = (data['guest_tiers'] as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  int get _totalCost {
    if (_venues.isEmpty || _guestTiers.isEmpty) return 0;
    final base = _venues[_selectedVenueIdx]['base_cost'] as int;
    final mult = (_guestTiers[_selectedGuestTierIdx]['multiplier'] as num).toDouble();
    return (base * mult).round();
  }

  int get _deposit => (_totalCost * 0.3).round();

  Widget _buildStepVenue() {
    return _buildOptionList(
      title: "Toy yeri seç",
      subtitle: "Toyu harada keçirmək istəyirsən?",
      items: _venues,
      selectedIdx: _selectedVenueIdx,
      labelKey: 'name',
      detailBuilder: (v) => "${v['base_cost']} AZN-dən başlayır · Prestij: ${'★' * (v['prestige'] as int)}",
      onSelect: (i) => setState(() => _selectedVenueIdx = i),
      onNext: () => setState(() => _step = 1),
    );
  }

  Widget _buildStepGuests() {
    return _buildOptionList(
      title: "Qonaq sayı",
      subtitle: "Neçə nəfəri dəvət etmək istəyirsən?",
      items: _guestTiers,
      selectedIdx: _selectedGuestTierIdx,
      labelKey: 'label',
      detailBuilder: (g) {
        final mult = (g['multiplier'] as num).toDouble();
        final base = _venues[_selectedVenueIdx]['base_cost'] as int;
        final cost = (base * mult).round();
        return "$cost AZN";
      },
      onSelect: (i) => setState(() => _selectedGuestTierIdx = i),
      onNext: () => setState(() => _step = 2),
    );
  }

  Widget _buildStepDate() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Toy tarixi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text("Neçə il sonra toy etmək istəyirsən?",
              style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundBtn(Icons.remove, () {
                if (_yearsAhead > 1) setState(() => _yearsAhead--);
              }),
              const SizedBox(width: 32),
              Text(
                "$_yearsAhead il",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFC0185A)),
              ),
              const SizedBox(width: 32),
              _roundBtn(Icons.add, () {
                if (_yearsAhead < 5) setState(() => _yearsAhead++);
              }),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "${widget.player.age + _yearsAhead} yaşında",
              style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
          ),
          const Spacer(),
          _nextButton("İrəli", () => setState(() => _step = 3)),
        ],
      ),
    );
  }

  Widget _buildStepSummary() {
    final venue = _venues[_selectedVenueIdx];
    final guestTier = _guestTiers[_selectedGuestTierIdx];
    final total = _totalCost;
    final deposit = _deposit;
    final canAfford = widget.player.money >= deposit;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Toy planı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _summaryRow("Yer", venue['name'] as String),
          _summaryRow("Qonaqlar", guestTier['label'] as String),
          _summaryRow("Tarix", "${widget.player.age + _yearsAhead} yaşında"),
          const Divider(height: 32),
          _summaryRow("Ümumi xərc", "$total AZN",
              valueStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFC0185A))),
          _summaryRow("İndi ödənişi (30%)", "$deposit AZN",
              valueStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: canAfford ? const Color(0xFF1565C0) : Colors.red)),
          const SizedBox(height: 8),
          if (!canAfford)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bahalı ödəniş üçün $deposit AZN lazımdır. Hazırda pulun: ${widget.player.money} AZN.",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          _nextButton(
            canAfford ? "Planı təsdiqlə ($deposit AZN ödə)" : "Pul çatmır",
            canAfford ? _confirm : null,
            color: canAfford ? const Color(0xFFC0185A) : Colors.grey,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _step = 2),
            child: const Text("Geri qayıt", style: TextStyle(color: Color(0xFF888888))),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final venue = _venues[_selectedVenueIdx];
    final total = _totalCost;
    final deposit = _deposit;

    widget.player.money -= deposit;
    widget.partner.weddingVenue = venue['name'] as String;
    widget.partner.weddingGuestTier = _selectedGuestTierIdx + 1;
    widget.partner.weddingScheduledAge = widget.player.age + _yearsAhead;
    widget.partner.weddingPlanStatus = "planned";
    widget.partner.weddingTotalCost = total;
    widget.partner.weddingDepositPaid = true;

    Navigator.pop(context, true);
  }

  Widget _buildOptionList({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    required int selectedIdx,
    required String labelKey,
    required String Function(Map<String, dynamic>) detailBuilder,
    required ValueChanged<int> onSelect,
    required VoidCallback onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final item = items[i];
                final selected = i == selectedIdx;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFC0185A).withValues(alpha: 0.08)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFFC0185A) : const Color(0xFFEEEEEE),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? const Color(0xFFC0185A) : const Color(0xFFCCCCCC),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item[labelKey] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? const Color(0xFFC0185A) : const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detailBuilder(item),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _nextButton("İrəli", onNext),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }

  Widget _nextButton(String label, VoidCallback? onTap, {Color color = const Color(0xFFC0185A)}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFC0185A).withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFC0185A), size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final steps = ["Yer", "Qonaqlar", "Tarix", "Xülasə"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "TOY PLANLAYICI",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFC0185A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: const Color(0xFFC0185A),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (i) {
                final done = i < _step;
                final active = i == _step;
                return Row(
                  children: [
                    if (i > 0)
                      Container(
                        width: 24,
                        height: 2,
                        color: done ? Colors.white : Colors.white30,
                      ),
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? Colors.white
                                : active
                                    ? Colors.white
                                    : Colors.white30,
                          ),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check, size: 14, color: Color(0xFFC0185A))
                                : Text(
                                    "${i + 1}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: active ? const Color(0xFFC0185A) : Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
      body: [
        _buildStepVenue(),
        _buildStepGuests(),
        _buildStepDate(),
        _buildStepSummary(),
      ][_step],
    );
  }
}
