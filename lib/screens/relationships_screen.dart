import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/player.dart';
import 'person_interaction_screen.dart';
import 'friend_interaction_screen.dart';

class RelationshipsScreen extends StatefulWidget {
  final Player player;
  final Function(String) onAction;
  const RelationshipsScreen({super.key, required this.player, required this.onAction});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  Map<String, dynamic>? _eventsData;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final String response = await rootBundle.loadString('assets/json/relationship_events.json');
      setState(() {
        _eventsData = json.decode(response);
      });
    } catch (e) {
      debugPrint("Error loading relationship events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Split family into sub-groups for section bands
    final parents   = widget.player.family.where((m) => m.relation == "Ana" || m.relation == "Ata").toList();
    final siblings  = widget.player.family.where((m) => m.relation == "Qardaş" || m.relation == "Bacı").toList();
    final partners  = widget.player.friends.where((f) => f.relationType == FriendRelationType.partner).toList();
    final friends   = widget.player.friends.where((f) => f.relationType != FriendRelationType.partner).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("MÜNASİBƏTLƏR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        children: [
          if (partners.isNotEmpty) ...[
            _sectionBand("Sevgilim", color: const Color(0xFFC0185A), leadingIcon: Icons.favorite),
            ...partners.map((f) => _friendRow(f)),
          ],
          if (parents.isNotEmpty) ...[
            _sectionBand("Valideynlər"),
            ...parents.map((m) => _familyRow(m)),
          ],
          if (siblings.isNotEmpty) ...[
            _sectionBand("Qardaş / Bacı"),
            ...siblings.map((m) => _familyRow(m)),
          ],
          if (friends.isNotEmpty) ...[
            _sectionBand("Dostlar"),
            ...friends.map((f) => _friendRow(f)),
          ],
        ],
      ),
    );
  }

  Widget _sectionBand(String title, {Color color = const Color(0xFF555555), IconData? leadingIcon}) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _familyRow(FamilyMember member) {
    return _personRow(
      name: "${member.name} ${member.surname}",
      subtitle: member.relation,
      gender: member.gender,
      relationship: member.relationship,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonInteractionScreen(
            player: widget.player,
            person: member,
            onAction: widget.onAction,
            eventsData: _eventsData,
          ),
        ),
      ).then((_) => setState(() {})),
    );
  }

  Widget _friendRow(SchoolMate friend) {
    final label = switch (friend.relationType) {
      FriendRelationType.partner    => "Sevgili",
      FriendRelationType.bestFriend => "Yaxın Dost",
      FriendRelationType.friend     => "Dost",
    };
    return _personRow(
      name: "${friend.name} ${friend.surname}",
      subtitle: label,
      gender: friend.gender,
      relationship: friend.relationship,
      isPartner: friend.relationType == FriendRelationType.partner,
      isBestFriend: friend.relationType == FriendRelationType.bestFriend,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendInteractionScreen(
            player: widget.player,
            friend: friend,
            onAction: widget.onAction,
            onFriendRemoved: () => setState(() => widget.player.friends.remove(friend)),
          ),
        ),
      ).then((_) => setState(() {})),
    );
  }

  Widget _personRow({
    required String name,
    required String subtitle,
    required Gender gender,
    required int relationship,
    required VoidCallback onTap,
    bool isPartner = false,
    bool isBestFriend = false,
  }) {
    final barColor = relationship > 70
        ? const Color(0xFF2EC95C)
        : relationship > 30
            ? const Color(0xFF4BBDFF)
            : const Color(0xFFFF6B6B);

    final avatarBg = gender == Gender.male
        ? const Color(0xFFDCEEFF)
        : const Color(0xFFFFDCEE);
    final avatarIconColor = gender == Gender.male
        ? const Color(0xFF1565C0)
        : const Color(0xFFAD1457);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: barColor, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarBg,
                    child: Icon(
                      gender == Gender.male ? Icons.face : Icons.face_3,
                      color: avatarIconColor,
                      size: 25,
                    ),
                  ),
                ),
                if (isPartner)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, size: 12, color: Color(0xFFE91E63)),
                    ),
                  ),
                if (isBestFriend)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 12, color: Color(0xFFF39C12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: relationship / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFEEEEEE),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
