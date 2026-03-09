import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import '../services/sound_manager.dart';

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

  bool get _isPartner => widget.friend.relationType == FriendRelationType.partner;

  bool get _canAskOut =>
      widget.friend.gender != widget.player.gender &&
      !widget.player.hasPartner &&
      !_isPartner;

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
      _ => _friendActions(),
    };
  }

  // ── Friend action module ─────────────────────────

  List<Widget> _friendActions() {
    return [
      _actionChip(Icons.chat_outlined,         "Söhbət et",            _handleTalk),
      _actionChip(Icons.people_outlined,        "Vaxt keçir",           _handleSpendTime),
      _actionChip(Icons.card_giftcard_outlined, "Hədiyyə ver (20 AZN)", _handleGift),
      _actionChip(Icons.celebration,            "Şənlik qur (50 AZN)",  _handleParty),
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
    return [
      _actionChip(Icons.restaurant_outlined,    "Görüşə get (30 AZN)",  _handleDate,         isRomantic: true),
      _actionChip(Icons.favorite_rounded,        "Sevgini ifadə et",     _handleExpressLove,  isRomantic: true),
      _actionChip(Icons.card_giftcard_outlined,  "Hədiyyə ver (20 AZN)", _handleGift,         isRomantic: true),
      _actionChip(Icons.celebration,             "Sürpriz et (40 AZN)",  _handleSurprise,     isRomantic: true),
      _actionChip(Icons.gavel_outlined,          "Mübahisə et",          _handlePartnerArgue, isNegative: true),
      _actionChip(Icons.heart_broken_outlined,   "Ayrıl",                _handleBreakUp,      isNegative: true),
    ];
  }

  // ── Friend handlers ──────────────────────────────

  void _handleTalk() {
    setState(() {
      final delta = 5 + _random.nextInt(6);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + 5).clamp(0, 100);
      _checkBestFriendUpgrade();
      final msg = "${widget.friend.name} ilə maraqlı söhbət etdin.";
      _addHistory(msg, relationshipDelta: delta, happinessDelta: 5);
      widget.onAction(msg);
      _showResultDialog("Söhbət", msg);
    });
  }

  void _handleSpendTime() {
    setState(() {
      final delta = 8 + _random.nextInt(8);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + 10).clamp(0, 100);
      _checkBestFriendUpgrade();
      final msg = "${widget.friend.name} ilə əla vaxt keçirdin.";
      _addHistory(msg, relationshipDelta: delta, happinessDelta: 10);
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
      widget.friend.relationship = (widget.friend.relationship + 15).clamp(0, 100);
      _checkBestFriendUpgrade();
      final msg = "${widget.friend.name} hədiyyəni çox bəyəndi.";
      _addHistory(msg, relationshipDelta: 15, moneyDelta: -20);
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
      widget.player.happiness = (widget.player.happiness + 15).clamp(0, 100);
      widget.player.health = (widget.player.health - 5).clamp(0, 100);
      widget.friend.relationship = (widget.friend.relationship + 20).clamp(0, 100);
      _checkBestFriendUpgrade();
      const msg = "Əla şənlik oldu! Çox əyləndiniz, amma sonra yoruldunuz.";
      _addHistory(msg, relationshipDelta: 20, happinessDelta: 15, healthDelta: -5, moneyDelta: -50);
      widget.onAction(msg);
      _showResultDialog("Şənlik 🎉", msg);
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
        widget.friend.relationType = FriendRelationType.partner; // ← state transition
        widget.player.hasPartner = true;
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

  void _handleDate() {
    if (widget.player.money < 30) {
      _showResultDialog("Xəta", "Görüş üçün kifayət qədər pulun yoxdur! (30 AZN lazımdır)");
      return;
    }
    setState(() {
      widget.player.money -= 30;
      widget.friend.relationship = (widget.friend.relationship + 10).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + 15).clamp(0, 100);
      final msg = "${widget.friend.name} ilə gözəl bir görüş keçirdin.";
      _addHistory(msg, relationshipDelta: 10, happinessDelta: 15, moneyDelta: -30);
      widget.onAction(msg);
      _showResultDialog("Görüş 🍽️", msg);
    });
  }

  void _handleExpressLove() {
    setState(() {
      final delta = 5 + _random.nextInt(8);
      widget.friend.relationship = (widget.friend.relationship + delta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + 10).clamp(0, 100);
      final msg = "${widget.friend.name} sənin sevgini duymaqdan çox xoşhal oldu.";
      _addHistory(msg, relationshipDelta: delta, happinessDelta: 10);
      widget.onAction(msg);
      _showResultDialog("Sevgi İfadəsi 💬", msg);
    });
  }

  void _handleSurprise() {
    if (widget.player.money < 40) {
      _showResultDialog("Xəta", "Sürpriz üçün kifayət qədər pulun yoxdur! (40 AZN lazımdır)");
      return;
    }
    setState(() {
      widget.player.money -= 40;
      widget.friend.relationship = (widget.friend.relationship + 20).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + 20).clamp(0, 100);
      final msg = "${widget.friend.name} sürprizindən çox təsirlənd! Bu an heç unutulmayacaq.";
      _addHistory(msg, relationshipDelta: 20, happinessDelta: 20, moneyDelta: -40);
      widget.onAction(msg);
      _showResultDialog("Sürpriz 🎁", msg);
    });
  }

  void _handlePartnerArgue() {
    setState(() {
      final relDelta = -10 - _random.nextInt(10); // -10 to -19
      widget.friend.relationship = (widget.friend.relationship + relDelta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness - 10).clamp(0, 100);
      final msg = "${widget.friend.name} ilə ciddi bir mübahisə etdiniz.";
      _addHistory(msg, relationshipDelta: relDelta, happinessDelta: -10);
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
      widget.friend.relationType = FriendRelationType.friend; // ← reverse transition
      widget.player.hasPartner = false;
      widget.friend.relationship = (widget.friend.relationship - 25).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness - 20).clamp(0, 100);
      final msg = "${widget.friend.name} ilə ayrıldın. Çox çətin idi.";
      _addHistory(msg, relationshipDelta: -25, happinessDelta: -20);
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
      FriendRelationType.partner    => ("Sevgili",    Colors.pink,       Icons.favorite),
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
                  _profileRow("Cins",
                      widget.friend.gender == Gender.male ? "Kişi" : "Qadın"),
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

  String _relationLabel(FriendRelationType type) => switch (type) {
        FriendRelationType.friend     => "Dost",
        FriendRelationType.bestFriend => "Yaxın Dost",
        FriendRelationType.partner    => "Sevgili",
      };

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
