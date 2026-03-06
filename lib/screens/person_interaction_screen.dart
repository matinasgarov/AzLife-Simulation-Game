import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import '../services/sound_manager.dart';

class PersonInteractionScreen extends StatefulWidget {
  final Player player;
  final FamilyMember person;
  final Function(String) onAction;
  final Map<String, dynamic>? eventsData;

  const PersonInteractionScreen({
    super.key, 
    required this.player, 
    required this.person, 
    required this.onAction,
    required this.eventsData,
  });

  @override
  State<PersonInteractionScreen> createState() => _PersonInteractionScreenState();
}

class _PersonInteractionScreenState extends State<PersonInteractionScreen> {
  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
        title: GestureDetector(
          onTap: () => _showFamilyProfile(widget.person),
          child: Text(widget.person.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
           _actionChip(Icons.chat_outlined, "Söhbət", () => _handleFamilyInteraction(widget.person, "conversation")),
           _actionChip(Icons.celebration_outlined, "Vaxt keçir", () => _handleFamilyInteraction(widget.person, "spendTime")),
           _actionChip(Icons.card_giftcard_outlined, "Hədiyyə (20 AZN)", () => _handleFamilyInteraction(widget.person, "gift")),
           _actionChip(Icons.attach_money, "Pul istə", () => _handleFamilyInteraction(widget.person, "ask_money")),
           _actionChip(Icons.gavel_outlined, "Mübahisə", () => _handleFamilyInteraction(widget.person, "argue"), isNegative: true),
        ],
      )
    );
  }

  void _showFamilyProfile(FamilyMember member) {
    showDialog(
        context: context,
        builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 8),
                        Text("(${member.relation})", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _profileRow("Yaş", "${member.age}"),
                        _profileRow("Status", member.maritalStatus),
                        _profileRow("Təhsil", member.education),
                        _profileRow("İş", member.job),
                        _profileRow("Xəstəlik", member.diseases.isEmpty ? "Yoxdur" : member.diseases.join(", ")),
                        const SizedBox(height: 10),
                        _statBar("Münasibət", member.relationship, Colors.green),
                        _statBar("Dindarlıq", member.religiousness, Colors.green),
                        _statBar("Səxavət", member.generosity, Colors.orange),
                        _statBar("Pul", (member.totalMoney / 100).clamp(0, 100).toInt(), Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ));
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

  Widget _actionChip(IconData icon, String label, VoidCallback onTap, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon, color: isNegative ? Colors.redAccent : Colors.blueAccent),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isNegative ? Colors.redAccent : Colors.black87)),
        onTap: () {
          SoundManager.playClick();
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: isNegative ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  void _handleFamilyInteraction(FamilyMember member, String type) {
    if (widget.eventsData == null) return;
    
    String logMsg = "";
    String resultText = "";

    setState(() {
      if (type == "conversation" || type == "spendTime") {
        List<dynamic> events = widget.eventsData!['parents'][type];
        var event = events[_random.nextInt(events.length)];
        
        resultText = event['text'].replaceAll("Atanla", "${member.relation}nla").replaceAll("Ananla", "${member.relation}nla").replaceAll("Atanın", "${member.relation}nın").replaceAll("Ananın", "${member.relation}nın");
        
        Map<String, dynamic> effects = event['effects'];
        if (effects.containsKey('happiness')) widget.player.happiness = (widget.player.happiness + (effects['happiness'] as int)).clamp(0, 100);
        if (effects.containsKey('relationship')) member.relationship = (member.relationship + (effects['relationship'] as int)).clamp(0, 100);
        
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
}
