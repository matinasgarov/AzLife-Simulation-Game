import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../services/sound_manager.dart';
import 'restaurant_picker_screen.dart';
import 'wedding_planner_screen.dart';

class FriendInteractionScreen extends StatefulWidget {
  final Player player;
  final SchoolMate friend;
  final Function(String) onAction;
  final VoidCallback onFriendRemoved;

  const FriendInteractionScreen({
    super.key,
    required this.player,
    required this.friend,
    required this.onAction,
    required this.onFriendRemoved,
  });

  @override
  State<FriendInteractionScreen> createState() => _FriendInteractionScreenState();
}

class _FriendInteractionScreenState extends State<FriendInteractionScreen> {
  final Random _random = Random();
  Map<String, dynamic>? _loveMessages;
  final Map<String, List<int>> _msgIndexes = {};

  static const List<String> _occupations = [
    "Tələbə", "Müəllim", "Həkim", "Mühəndis", "Dizayner",
    "Mühasib", "Hüquqşünas", "Proqramçı", "Jurnalist", "Menecer",
  ];

  @override
  void initState() {
    super.initState();
    _loadLoveMessages();
  }

  Future<void> _loadLoveMessages() async {
    try {
      final data = await rootBundle.loadString('assets/json/love_interactions.json');
      if (mounted) setState(() => _loveMessages = json.decode(data));
    } catch (e) {
      debugPrint("Could not load love_interactions.json: $e");
    }
  }

  /// Returns a random message from the given key, cycling without repeats.
  String _pickMessage(String key, String fallback) {
    if (_loveMessages == null) return fallback;
    final section = _loveMessages![key] as Map<String, dynamic>?;
    if (section == null) return fallback;
    final messages = List<String>.from(section['messages'] as List);
    if (!_msgIndexes.containsKey(key) || _msgIndexes[key]!.isEmpty) {
      _msgIndexes[key] = List.generate(messages.length, (i) => i)..shuffle(_random);
    }
    final idx = _msgIndexes[key]!.removeLast();
    return messages[idx].replaceAll('{name}', widget.friend.name);
  }

  /// Scales a positive stat delta by 0.35 when relationship is below 40.
  int _scale(int value) {
    if (value <= 0) return value;
    return widget.friend.relationship < 40 ? (value * 0.35).round() : value;
  }

  bool get _isPartner => widget.friend.relationType == FriendRelationType.partner;
  bool get _isEx => widget.friend.relationType == FriendRelationType.ex;

  bool get _canAskOut =>
      widget.player.age >= 16 &&
      widget.friend.gender != widget.player.gender &&
      !widget.player.hasPartner &&
      !_isPartner &&
      !_isEx;

  // ── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
        title: GestureDetector(
          onTap: _showProfile,
          child: Text(
            widget.friend.name,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRelationBadge(),
          const SizedBox(height: 16),
          // ── State machine: routes to the correct action module ──
          ..._buildActionList(),
        ],
      ),
    );
  }

  // ── State machine dispatcher ─────────────────────
  //
  // This is the single point of truth for which UI module is active.
  // Calling setState() with a new relationType value causes build() to
  // re-evaluate this switch and render the correct action set.

  List<Widget> _buildActionList() {
    return switch (widget.friend.relationType) {
      FriendRelationType.partner => _partnerActions(),
      FriendRelationType.ex      => _exActions(),
      _                          => _friendActions(),
    };
  }

  // ── Friend action module ─────────────────────────

  List<Widget> _friendActions() {
    return [
      _actionChip(Icons.chat_outlined,         "Söhbət et",            _handleTalk),
      _actionChip(Icons.people_outlined,        "Vaxt keçir",           _handleSpendTime),
      _actionChip(Icons.card_giftcard_outlined, "Hədiyyə ver (20 AZN)", _handleGift),
      _actionChip(Icons.celebration,            "Party-lə (50 AZN)",  _handleParty),
      if (_canAskOut)
        _actionChip(
          Icons.favorite_outline,
          "Münasibətə dəvət et",
          _handleAskOut,
          isRomantic: true,
        ),
      _actionChip(
        Icons.person_remove_outlined,
        "Dostluğu bitir",
        _handleEndContact,
        isNegative: true,
      ),
    ];
  }

  // ── Partner action module ────────────────────────

  List<Widget> _partnerActions() {
    final ps = widget.friend.partnerStatus;

    // Actions available for all partner statuses
    final base = [
      _actionChip(Icons.restaurant_outlined,   "Görüşə get",           _handleDate,         isRomantic: true),
      _actionChip(Icons.favorite_rounded,       "Sevgini ifadə et",     _handleExpressLove,  isRomantic: true),
      _actionChip(Icons.card_giftcard_outlined, "Hədiyyə ver (20 AZN)", _handleGift,         isRomantic: true),
      _actionChip(Icons.celebration,            "Sürpriz et (40 AZN)",  _handleSurprise,     isRomantic: true),
    ];

    if (ps == PartnerStatus.married) {
      return [
        ...base,
        _actionChip(Icons.gavel_outlined,        "Mübahisə et",    _handlePartnerArgue, isNegative: true),
        _actionChip(Icons.heart_broken_outlined,  "Boşan",          _handleBreakUp,      isNegative: true),
      ];
    }

    if (ps == PartnerStatus.fiance) {
      return [
        ...base,
        _actionChip(Icons.diamond_outlined, "Toy planlaşdır", _handleWeddingPlan, isRomantic: true),
        _actionChip(Icons.heart_broken_outlined, "Nişanı pozaq", _handleBreakUp, isNegative: true),
      ];
    }

    // PartnerStatus.partner
    final cooldown = widget.friend.proposalCooldownYears;
    final canPropose = widget.player.age >= 18 &&
        widget.friend.relationship >= 70 &&
        cooldown <= 0;
    return [
      ...base,
      if (canPropose)
        _actionChip(Icons.diamond_outlined, "Evlilik təklifi et", _handleProposal, isRomantic: true),
      if (!canPropose && widget.player.age >= 18 && widget.friend.relationship >= 70 && cooldown > 0)
        _disabledChip(Icons.diamond_outlined, "Evlilik təklifi et ($cooldown il gözlə)"),
      _actionChip(Icons.gavel_outlined,       "Mübahisə et", _handlePartnerArgue, isNegative: true),
      _actionChip(Icons.heart_broken_outlined, "Ayrıl",       _handleBreakUp,      isNegative: true),
    ];
  }

  Widget _disabledChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        tileColor: const Color(0xFFF5F5F5),
      ),
    );
  }

  // ── Ex action module ────────────────────────────

  List<Widget> _exActions() {
    final canAskOutAgain = widget.player.age >= 16 &&
        widget.friend.gender != widget.player.gender &&
        !widget.player.hasPartner &&
        widget.friend.relationship >= 40;
    return [
      _actionChip(Icons.chat_outlined,    "Söhbət et",     _handleTalk),
      _actionChip(Icons.gavel_outlined,   "Mübahisə et",   _handlePartnerArgue, isNegative: true),
      if (canAskOutAgain)
        _actionChip(Icons.favorite_outline, "Yenidən birlikdə ol", _handleAskOutEx, isRomantic: true),
      _actionChip(Icons.person_remove_outlined, "Əlaqəni kəs", _handleEndContact, isNegative: true),
    ];
  }

  void _handleAskOutEx() {
    setState(() {
      final score = widget.friend.relationship + _random.nextInt(41) - 10;
      if (score >= 80) {
        widget.friend.relationType = FriendRelationType.partner;
        widget.player.hasPartner = true;
        widget.friend.relationship = (widget.friend.relationship + 15).clamp(0, 100);
        widget.player.happiness = (widget.player.happiness + 10).clamp(0, 100);
        SoundManager.playSuccess();
        final msg = "${widget.friend.name} ilə yenidən birlikdə oldun!";
        _addHistory(msg, relationshipDelta: 15, happinessDelta: 10);
        widget.onAction(msg);
        _showResultDialog("Yenidən birlikdə!", msg);
      } else {
        widget.friend.relationship = (widget.friend.relationship - 10).clamp(0, 100);
        SoundManager.playFail();
        final msg = "${widget.friend.name} təklifini rədd etdi.";
        _addHistory(msg, relationshipDelta: -10);
        widget.onAction(msg);
        _showResultDialog("Rədd", msg);
      }
    });
  }

  // ── Friend handlers ──────────────────────────────

  void _handleTalk() {
    setState(() {
      final raw = 2 + _random.nextInt(3);
      final delta = _scale(raw);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + _scale(3)).clamp(0, 100);
      _checkBestFriendUpgrade();
      final msg = "${widget.friend.name} ilə maraqlı söhbət etdin.";
      _addHistory(msg, relationshipDelta: delta, happinessDelta: _scale(3));
      widget.onAction(msg);
      _showResultDialog("Söhbət", msg);
    });
  }

  void _handleSpendTime() {
    setState(() {
      final raw = 3 + _random.nextInt(4);
      final delta = _scale(raw);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + _scale(5)).clamp(0, 100);
      _checkBestFriendUpgrade();
      final msg = "${widget.friend.name} ilə əla vaxt keçirdin.";
      _addHistory(msg, relationshipDelta: delta, happinessDelta: _scale(5));
      widget.onAction(msg);
      _showResultDialog("Vaxt Keçirmək", msg);
    });
  }

  void _handleGift() {
    if (widget.player.money < 20) {
      _showResultDialog("Xəta", "Hədiyyə almaq üçün kifayət qədər pulun yoxdur!");
      return;
    }
    setState(() {
      widget.player.money -= 20;
      final delta = _scale(6);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      _checkBestFriendUpgrade();
      final msg = _pickMessage('hediyye_ver', "${widget.friend.name} hədiyyəni çox bəyəndi.");
      _addHistory(msg, relationshipDelta: delta, moneyDelta: -20);
      widget.onAction(msg);
      _showResultDialog("Hədiyyə", msg);
    });
  }

  void _handleParty() {
    if (widget.player.money < 50) {
      _showResultDialog("Xəta", "Şənlik üçün kifayət qədər pulun yoxdur! (50 AZN lazımdır)");
      return;
    }
    setState(() {
      widget.player.money -= 50;
      widget.player.happiness = (widget.player.happiness + _scale(8)).clamp(0, 100);
      widget.player.health = (widget.player.health - 3).clamp(0, 100);
      final delta = _scale(8);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      _checkBestFriendUpgrade();
      const msg = "Əla şənlik oldu! Çox əyləndiniz, amma sonra yoruldunuz.";
      _addHistory(msg, relationshipDelta: delta, happinessDelta: _scale(8), healthDelta: -3, moneyDelta: -50);
      widget.onAction(msg);
      _showResultDialog("Şənlik", msg);
    });
  }

  // ── Transition: Friend → Partner ─────────────────
  //
  // This is the state machine trigger. On success it sets relationType = partner
  // and calls setState(). The next build() routes to _partnerActions() automatically.
  // All history on widget.friend is preserved — same object, no data migration needed.

  void _handleAskOut() {
    final score = widget.friend.relationship + _random.nextInt(30) - 10;
    if (score >= 65) {
      setState(() {
        widget.friend.relationType = FriendRelationType.partner;
        widget.player.hasPartner = true;
        widget.friend.partnerStartAge = widget.player.age;
        widget.friend.occupation = _occupations[_random.nextInt(_occupations.length)];
        widget.friend.netWorth = 500 + _random.nextInt(49501); // 500–50000
        final msg = "${widget.friend.name} təklifini qəbul etdi! Artıq sevgilinizsiz.";
        _addHistory(msg, relationshipDelta: 20, happinessDelta: 15);
        widget.onAction(msg);
      });
      SoundManager.playSuccess();
      _showResultDialog(
        "Uğurlu! 💕",
        "${widget.friend.name} təklifini qəbul etdi!\n\nMünasibət modulu yeniləndi.",
      );
    } else {
      setState(() {
        widget.friend.relationship = (widget.friend.relationship - 10).clamp(0, 100);
        final msg = "${widget.friend.name} təklifini nəzakətlə rədd etdi.";
        _addHistory(msg, relationshipDelta: -10, happinessDelta: -5);
        widget.onAction(msg);
      });
      SoundManager.playFail();
      _showResultDialog(
        "Rədd edildi",
        "${widget.friend.name} təklifini rədd etdi. Aramızda bir qəripəlik yarandı.",
      );
    }
  }

  // ── Partner handlers ─────────────────────────────

  Future<void> _handleDate() async {
    final restaurant = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => RestaurantPickerScreen(player: widget.player)),
    );
    if (restaurant == null || !mounted) return;
    final cost = restaurant['cost_azn'] as int;
    final tier = (restaurant['price_range'] as String).length.clamp(1, 4);
    final relBoost = [3, 5, 7, 10][tier - 1];
    setState(() {
      widget.player.money -= cost;
      final relDelta = _scale(relBoost);
      final hapDelta = _scale(5 + tier * 2);
      widget.friend.relationship = (widget.friend.relationship + relDelta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + hapDelta).clamp(0, 100);
      final restaurantName = restaurant['name'] as String;
      final base = _pickMessage('goruse_get', "${widget.friend.name} ilə gözəl bir görüş keçirdin.");
      final msg = "$base ($restaurantName)";
      _addHistory(msg, relationshipDelta: relDelta, happinessDelta: hapDelta, moneyDelta: -cost);
      widget.onAction(msg);
      _showResultDialog("Görüş", msg);
    });
  }

  Future<void> _handleWeddingPlan() async {
    if (widget.friend.weddingPlanStatus == "planned") {
      _showResultDialog(
        "Toy planı",
        "Toy artıq planlaşdırılıb!\n"
        "Yer: ${widget.friend.weddingVenue}\n"
        "Tarix: ${widget.friend.weddingScheduledAge} yaşında\n"
        "Ümumi xərc: ${widget.friend.weddingTotalCost} AZN",
      );
      return;
    }
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WeddingPlannerScreen(player: widget.player, partner: widget.friend),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {});
      final msg = "${widget.friend.name} ilə toy planlaşdırıldı! (${widget.friend.weddingVenue}, ${widget.friend.weddingScheduledAge} yaşında)";
      widget.onAction(msg);
      _showResultDialog("Toy planlaşdırıldı!", msg);
    }
  }

  void _handleExpressLove() {
    setState(() {
      final raw = 2 + _random.nextInt(4);
      final delta = _scale(raw);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + _scale(5)).clamp(0, 100);
      final msg = _pickMessage('sevgini_ifade_et', "${widget.friend.name} sənin sevgini duymaqdan çox xoşhal oldu.");
      _addHistory(msg, relationshipDelta: delta, happinessDelta: _scale(5));
      widget.onAction(msg);
      _showResultDialog("Sevgi İfadəsi", msg);
    });
  }

  void _handleSurprise() {
    if (widget.player.money < 40) {
      _showResultDialog("Xəta", "Sürpriz üçün kifayət qədər pulun yoxdur! (40 AZN lazımdır)");
      return;
    }
    setState(() {
      widget.player.money -= 40;
      final relDelta = _scale(8);
      final hapDelta = _scale(8);
      widget.friend.relationship = (widget.friend.relationship + relDelta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + hapDelta).clamp(0, 100);
      final msg = _pickMessage('surpriz_et', "${widget.friend.name} sürprizindən çox təsirlənd!");
      _addHistory(msg, relationshipDelta: relDelta, happinessDelta: hapDelta, moneyDelta: -40);
      widget.onAction(msg);
      _showResultDialog("Sürpriz", msg);
    });
  }

  void _handlePartnerArgue() {
    setState(() {
      final relDelta = -5 - _random.nextInt(6); // -5 to -10
      widget.friend.relationship = (widget.friend.relationship + relDelta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness - 5).clamp(0, 100);
      final msg = "${widget.friend.name} ilə ciddi bir mübahisə etdiniz.";
      _addHistory(msg, relationshipDelta: relDelta, happinessDelta: -5);
      widget.onAction(msg);
      _showResultDialog("Mübahisə", msg);
    });
  }

  // ── Transition: Partner → Friend (break up) ──────
  //
  // Reverse state transition. Downgrades relationType back to friend,
  // clears player.hasPartner. History is fully preserved on the object.

  void _handleBreakUp() async {
    final confirmed = await _showConfirmDialog(
      title: "Ayrıl",
      content: "${widget.friend.name} ilə münasibəti bitirmək istədiyindən əminsən?",
      confirmLabel: "Bəli, Ayrıl",
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      widget.friend.relationType = FriendRelationType.ex;
      widget.player.hasPartner = false;
      widget.friend.relationship = _random.nextInt(10); // 0-9, below 10%
      widget.friend.partnerStatus = PartnerStatus.partner; // reset status
      widget.friend.proposalCooldownYears = 0;
      widget.friend.weddingPlanStatus = "none";
      widget.friend.weddingScheduledAge = 0;
      widget.friend.weddingDepositPaid = false;
      widget.player.happiness = (widget.player.happiness - 20).clamp(0, 100);
      final msg = "${widget.friend.name} ilə ayrıldın. Çox çətin idi.";
      _addHistory(msg, happinessDelta: -20);
      widget.onAction(msg);
    });
    SoundManager.playFail();
    _showResultDialog("Ayrılıq", "${widget.friend.name} ilə münasibətin başa çatdı.");
  }

  // ── End contact (remove from friends list) ───────

  void _handleEndContact() async {
    final confirmed = await _showConfirmDialog(
      title: "Dostluğu Bitir",
      content: "${widget.friend.name} ilə dostluğu tamamilə bitirmək istəyirsən?",
      confirmLabel: "Bəli, Bitir",
    );
    if (confirmed != true || !mounted) return;
    final msg = "${widget.friend.name} ilə əlaqəni kəsdin.";
    widget.onAction(msg);
    widget.onFriendRemoved();
    Navigator.pop(context);
  }

  // ── Shared confirmation dialog ───────────────────

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Xeyr"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── Auto-upgrade to Best Friend ──────────────────

  void _checkBestFriendUpgrade() {
    if (widget.friend.relationship >= 80 &&
        widget.friend.relationType == FriendRelationType.friend) {
      widget.friend.relationType = FriendRelationType.bestFriend;
    }
  }

  // ── Relation badge (reacts to relationType) ──────

  Widget _buildRelationBadge() {
    final (label, color, icon) = switch (widget.friend.relationType) {
      FriendRelationType.friend     => ("Dost",       Colors.blueAccent, Icons.people),
      FriendRelationType.bestFriend => ("Yaxın Dost", Colors.purple,     Icons.people_alt),
      FriendRelationType.ex         => ("Keçmiş",     const Color(0xFF78909C), Icons.heart_broken),
      FriendRelationType.partner    => switch (widget.friend.partnerStatus) {
        PartnerStatus.fiance  => ("Nişanlı",        const Color(0xFFC0185A), Icons.diamond),
        PartnerStatus.married => (widget.friend.gender == Gender.female ? "Arvad" : "Ər", const Color(0xFF8B0000), Icons.favorite),
        _                     => ("Sevgili",         Colors.pink, Icons.favorite),
      },
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            "Münasibət: ${widget.friend.relationship}%",
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Profile dialog ───────────────────────────────

  void _showProfile() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isPartner ? Colors.pink : Colors.blueAccent, // driven by _isPartner getter
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.friend.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    _relationLabel(widget.friend.relationType),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _profileRow("Yaş", "${widget.friend.age}"),
                  _profileRow("Cins", widget.friend.gender == Gender.male ? "Kişi" : "Qadın"),
                  if (_isPartner && widget.friend.occupation.isNotEmpty)
                    _profileRow("Peşə", widget.friend.occupation),
                  if (_isPartner && widget.friend.partnerStartAge > 0)
                    _profileRow("Birlikdə", "${widget.player.age - widget.friend.partnerStartAge} il"),
                  if (_isPartner && widget.friend.netWorth > 0)
                    _profileRow("Sərvət", "${widget.friend.netWorth} AZN"),
                  const SizedBox(height: 10),
                  _statBar("Münasibət", widget.friend.relationship, Colors.green),
                  _statBar("Ağıl",      widget.friend.smarts,       Colors.blueAccent),
                  _statBar("Görünüş",   widget.friend.looks,        Colors.orange),
                  _statBar("Sağlamlıq", widget.friend.health,       Colors.redAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ────────────────────────────

  String _relationLabel(FriendRelationType type) {
    if (type == FriendRelationType.partner) {
      return switch (widget.friend.partnerStatus) {
        PartnerStatus.fiance  => "Nişanlı",
        PartnerStatus.married => widget.friend.gender == Gender.female ? "Arvad" : "Ər",
        _                     => "Sevgili",
      };
    }
    return switch (type) {
      FriendRelationType.friend     => "Dost",
      FriendRelationType.bestFriend => "Yaxın Dost",
      FriendRelationType.ex         => "Keçmiş",
      _                             => "Sevgili",
    };
  }

  Widget _actionChip(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isNegative = false,
    bool isRomantic = false,
  }) {
    final color = isNegative
        ? Colors.redAccent
        : isRomantic
            ? Colors.pink
            : Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.redAccent : Colors.black87,
          ),
        ),
        onTap: () {
          SoundManager.playClick();
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: color.withValues(alpha: 0.25)),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  // ── Proposal system (Task 12) ────────────────────

  void _handleProposal() {
    const locations = [
      {"name": "Restoran",  "bonus": 1.2},
      {"name": "Park",      "bonus": 1.0},
      {"name": "Ev",        "bonus": 0.9},
      {"name": "Sahil",     "bonus": 1.15},
      {"name": "Dam üstü",  "bonus": 1.1},
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Yer seçin", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: locations.map((loc) => ListTile(
            leading: const Icon(Icons.place_outlined, color: Color(0xFFE91E63)),
            title: Text(loc["name"] as String),
            onTap: () {
              Navigator.pop(ctx);
              _resolveProposal(loc["bonus"] as double, loc["name"] as String);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _resolveProposal(double locationBonus, String locationName) {
    final successChance = (widget.friend.relationship / 100) * locationBonus;
    final success = _random.nextDouble() < successChance;
    setState(() {
      if (success) {
        widget.friend.partnerStatus = PartnerStatus.fiance;
        widget.friend.relationship = (widget.friend.relationship + 30).clamp(0, 100);
        widget.player.happiness = (widget.player.happiness + 30).clamp(0, 100);
        final msg = "${widget.friend.name} evlilik təklifini qəbul etdi! $locationName-da nişanlandınız!";
        _addHistory(msg, relationshipDelta: 30, happinessDelta: 30);
        widget.onAction(msg);
        SoundManager.playSuccess();
        _showResultDialog("Evlilik Təklifi", msg);
      } else {
        widget.friend.proposalCooldownYears = 2;
        widget.friend.relationship = (widget.friend.relationship - 10).clamp(0, 100);
        widget.player.happiness = (widget.player.happiness - 15).clamp(0, 100);
        final msg = "${widget.friend.name} hələ hazır deyildir dedi.";
        _addHistory(msg, relationshipDelta: -10, happinessDelta: -15);
        widget.onAction(msg);
        SoundManager.playFail();
        _showResultDialog("Evlilik Təklifi", msg);
      }
    });
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Davam et", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addHistory(
    String message, {
    int? relationshipDelta,
    int? happinessDelta,
    int? healthDelta,
    int? moneyDelta,
  }) {
    final effects = <String>[];
    if (relationshipDelta != null && relationshipDelta != 0) {
      effects.add("Münasibət ${relationshipDelta > 0 ? '+' : ''}$relationshipDelta");
    }
    if (happinessDelta != null && happinessDelta != 0) {
      effects.add("Xoşbəxtlik ${happinessDelta > 0 ? '+' : ''}$happinessDelta");
    }
    if (healthDelta != null && healthDelta != 0) {
      effects.add("Sağlamlıq ${healthDelta > 0 ? '+' : ''}$healthDelta");
    }
    if (moneyDelta != null && moneyDelta != 0) {
      effects.add("Pul ${moneyDelta > 0 ? '+' : ''}$moneyDelta AZN");
    }

    final suffix = effects.isEmpty ? "" : " (${effects.join(', ')})";
    widget.friend.interactionHistory
        .insert(0, "[Yaş ${widget.player.age}] $message$suffix");

    if (widget.friend.interactionHistory.length > 40) {
      widget.friend.interactionHistory
          .removeRange(40, widget.friend.interactionHistory.length);
    }
  }
}
