import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../services/sound_manager.dart';

class RelationshipsScreen extends StatefulWidget {
  final Player player;
  final Function(String) onAction;
  const RelationshipsScreen({super.key, required this.player, required this.onAction});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  final Random _random = Random();
  Map<String, dynamic>? _eventsData;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final String response = await rootBundle.loadString('assets/relationship_events.json');
      setState(() {
        _eventsData = json.decode(response);
      });
    } catch (e) {
      debugPrint("Error loading relationship events: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Münasibətlər", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Ailə"),
            _buildFamilyList(),
            if (widget.player.friends.isNotEmpty) ...[
              _buildSectionHeader("Dostlar"),
              _buildFriendList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildFamilyList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.player.family.length,
      itemBuilder: (context, index) {
        final member = widget.player.family[index];
        return _buildFamilyCard(member);
      },
    );
  }

  Widget _buildFamilyCard(FamilyMember member) {
    String incomeLabel = _getIncomeLabel(member.monthlyIncome);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(member.relation == "Ata" || member.relation == "Qardaş" ? Icons.face : Icons.face_3, color: Colors.blueAccent),
        ),
        title: Text("${member.name} ${member.surname} (${member.relation})", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${member.job} • $incomeLabel (${member.monthlyIncome} AZN)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 5),
            _miniStatBar("Münasibət", member.relationship, Colors.pinkAccent),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _statusStatBar("Təhsil", member.education, 100, Colors.grey, isTextOnly: true),
                _statusStatBar("Səxavət", _getStatValueLabel(member.generosity), member.generosity, Colors.orange),
                _statusStatBar("Dindarlıq", _getStatValueLabel(member.religiousness), member.religiousness, Colors.green),
                _statusStatBar("Maddi vəziyyət", _getWealthLabel(member.totalMoney), (member.totalMoney / 100).clamp(0, 100).toInt(), Colors.blue),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _actionChip(Icons.chat_outlined, "Söhbət", () => _handleFamilyInteraction(member, "conversation")),
                    _actionChip(Icons.celebration_outlined, "Vaxt keçir", () => _handleFamilyInteraction(member, "spendTime")),
                    _actionChip(Icons.card_giftcard_outlined, "Hədiyyə (20)", () => _handleFamilyInteraction(member, "gift")),
                    _actionChip(Icons.attach_money, "Pul istə", () => _handleFamilyInteraction(member, "ask_money")),
                    _actionChip(Icons.gavel_outlined, "Mübahisə", () => _handleFamilyInteraction(member, "argue"), isNegative: true),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getIncomeLabel(int income) {
    if (income < 500) return "Çox az";
    if (income < 800) return "Az";
    if (income < 1000) return "Orta";
    if (income < 2000) return "Yuxarı orta";
    if (income < 3000) return "Çox";
    return "Həddindən çox";
  }

  String _getWealthLabel(int total) {
    if (total < 1000) return "Kasıb";
    if (total < 5000) return "Orta";
    return "Varlı";
  }

  String _getStatValueLabel(int value) {
    if (value > 80) return "Çox yüksək";
    if (value > 60) return "Yüksək";
    if (value > 40) return "Orta";
    if (value > 20) return "Aşağı";
    return "Çox aşağı";
  }

  Widget _statusStatBar(String label, String valueLabel, int value, Color color, {bool isTextOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(valueLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          if (!isTextOnly) ...[
            const SizedBox(height: 4),
            _miniStatBar("", value, color),
          ]
        ],
      ),
    );
  }

  Widget _miniStatBar(String label, int value, Color color) {
    return Row(
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap, {bool isNegative = false}) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: isNegative ? Colors.red : Colors.blueAccent),
      label: Text(label, style: TextStyle(fontSize: 12, color: isNegative ? Colors.red : Colors.blueAccent)),
      onPressed: () {
        SoundManager.playClick();
        onTap();
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: isNegative ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
    );
  }

  void _handleFamilyInteraction(FamilyMember member, String type) {
    if (_eventsData == null) return;
    
    String logMsg = "";
    String resultText = "";

    setState(() {
      if (type == "conversation" || type == "spendTime") {
        List<dynamic> events = _eventsData!['parents'][type];
        var event = events[_random.nextInt(events.length)];
        
        resultText = event['text'].replaceAll("Atanla", "${member.relation}nla").replaceAll("Ananla", "${member.relation}nla").replaceAll("Atanın", "${member.relation}nın").replaceAll("Ananın", "${member.relation}nın");
        
        Map<String, dynamic> effects = event['effects'];
        if (effects.containsKey('happiness')) widget.player.happiness = (widget.player.happiness + (effects['happiness'] as int)).clamp(0, 100);
        if (effects.containsKey('relationship')) member.relationship = (member.relationship + (effects['relationship'] as int)).clamp(0, 100);
        if (effects.containsKey('money')) widget.player.money += (effects['money'] as int);
        if (effects.containsKey('health')) widget.player.health = (widget.player.health + (effects['health'] as int)).clamp(0, 100);
        
        logMsg = resultText;
        _showResultDialog(type == "conversation" ? "Söhbət" : "Vaxt Keçirmək", resultText);
      } else if (type == "gift") {
        if (widget.player.money >= 20) {
          widget.player.money -= 20;
          member.relationship = (member.relationship + 15).clamp(0, 100);
          logMsg = "${member.relation} hədiyyəni çox bəyəndi.";
          _showResultDialog("Hədiyyə", logMsg);
        } else {
          _showResultDialog("Xəta", "Hədiyyə almaq üçün kifayət qədər pulun yoxdur!");
          return;
        }
      } else if (type == "ask_money") {
        if (member.askedMoneyThisYear) {
          _showResultDialog("Diqqət", "Bu il artıq ${member.relation}-dan pul istəmisən.");
          return;
        }
        member.askedMoneyThisYear = true;
        double chance = (member.relationship * 0.4) + (member.generosity * 0.4) + ((member.totalMoney / 10000) * 20);
        if (_random.nextInt(100) < chance) {
          int amount = 5 + _random.nextInt(25);
          if (member.totalMoney < amount) amount = member.totalMoney;
          widget.player.money += amount;
          member.totalMoney -= amount;
          logMsg = "${member.relation} sənə $amount AZN verdi.";
          _showResultDialog("Pul istə", logMsg);
        } else {
          member.relationship = (member.relationship - 5).clamp(0, 100);
          logMsg = "${member.relation} sənə pul verməkdən imtina etdi.";
          _showResultDialog("Rədd edildi", logMsg);
        }
      } else if (type == "argue") {
        member.relationship = (member.relationship - 15).clamp(0, 100);
        widget.player.happiness = (widget.player.happiness - 10).clamp(0, 100);
        logMsg = "${member.relation} ilə mübahisə etdin.";
        _showResultDialog("Mübahisə", logMsg);
      }
      
      if (logMsg.isNotEmpty) widget.onAction(logMsg);
    });
  }

  void _handleFriendInteraction(SchoolMate friend, String type) {
    String logMsg = "";
    setState(() {
      switch (type) {
        case "chat":
          friend.relationship = (friend.relationship + _random.nextInt(5) + 2).clamp(0, 100);
          logMsg = "Dostunla söhbət etdin.";
          _showResultDialog("Söhbət", logMsg);
          break;
        case "spend_time":
          friend.relationship = (friend.relationship + _random.nextInt(8) + 5).clamp(0, 100);
          widget.player.happiness = (widget.player.happiness + 5).clamp(0, 100);
          logMsg = "Dostunla vaxt keçirdin.";
          _showResultDialog("Birlikdə Vaxt", logMsg);
          break;
        case "gift":
          if (widget.player.money >= 20) {
            widget.player.money -= 20;
            friend.relationship = (friend.relationship + 15).clamp(0, 100);
            logMsg = "Dostuna hədiyyə verdin.";
            _showResultDialog("Hədiyyə", logMsg);
          } else {
            _showResultDialog("Xəta", "Kifayət qədər pulun yoxdur!");
            return;
          }
          break;
        case "argue":
          friend.relationship = (friend.relationship - 15).clamp(0, 100);
          widget.player.happiness = (widget.player.happiness - 10).clamp(0, 100);
          logMsg = "Dostunla mübahisə etdin.";
          _showResultDialog("Mübahisə", logMsg);
          break;
      }
      if (logMsg.isNotEmpty) widget.onAction(logMsg);
    });
  }

  Widget _buildFriendList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.player.friends.length,
      itemBuilder: (context, index) {
        final friend = widget.player.friends[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildFriendCard(SchoolMate friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(friend.gender == Gender.male ? Icons.face : Icons.face_3, color: Colors.blueAccent),
        ),
        title: Text("${friend.name} ${friend.surname}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: _miniStatBar("Münasibət", friend.relationship, Colors.blueAccent),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _statusStatBar("Ağıl", "${friend.smarts}%", friend.smarts, Colors.orange),
                _statusStatBar("Görünüş", "${friend.looks}%", friend.looks, Colors.pink),
                _statusStatBar("Sağlamlıq", "${friend.health}%", friend.health, Colors.green),
                _statusStatBar("Pul", "${friend.money} AZN", (friend.money / 10).clamp(0, 100).toInt(), Colors.blue),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _actionChip(Icons.chat_outlined, "Söhbət", () => _handleFriendInteraction(friend, "chat")),
                    _actionChip(Icons.celebration_outlined, "Vaxt keçir", () => _handleFriendInteraction(friend, "spend_time")),
                    _actionChip(Icons.card_giftcard_outlined, "Hədiyyə (20)", () => _handleFriendInteraction(friend, "gift")),
                    _actionChip(Icons.gavel_outlined, "Mübahisə", () => _handleFriendInteraction(friend, "argue"), isNegative: true),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
