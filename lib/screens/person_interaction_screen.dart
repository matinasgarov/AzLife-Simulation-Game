import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import '../services/sound_manager.dart';
import 'mini_games_screen.dart';

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
    if (!widget.person.isAlive) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          iconTheme: const IconThemeData(color: Colors.blueAccent),
          title: Text(widget.person.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.brightness_5, size: 64, color: Color(0xFF78909C)),
              const SizedBox(height: 16),
              Text("${widget.person.name} ${widget.person.surname}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Vəfat edib", style: TextStyle(fontSize: 16, color: Color(0xFF78909C))),
              const SizedBox(height: 4),
              Text("Allah rəhmət eləsin, ondan gəldik ona gedəcəyik", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    final bool isFather = _isFather(widget.person);
    final bool isCriticalRelationship = widget.person.relationship < 15;
    final bool isSibling = _isSibling(widget.person);
    final bool canTalkToSibling = !isSibling || widget.person.age >= 7;
    final bool canBorrowFromSibling = isSibling && widget.person.age >= 18;

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
           if (canTalkToSibling)
             _actionChip(Icons.chat_outlined, "Söhbət", () => _handleFamilyInteraction(widget.person, "conversation")),

           _actionChip(Icons.celebration_outlined, "Vaxt keçir", () => _handleFamilyInteraction(widget.person, "spendTime")),
           _actionChip(Icons.card_giftcard_outlined, "Hədiyyə (20 AZN)", () => _handleFamilyInteraction(widget.person, "gift")),

           if (!isSibling || canBorrowFromSibling)
             _actionChip(Icons.attach_money, "Pul istə", () => _handleFamilyInteraction(widget.person, "ask_money")),

           _actionChip(Icons.gavel_outlined, "Mübahisə", () => _handleFamilyInteraction(widget.person, "argue"), isNegative: true),

           if (isFather && isCriticalRelationship)
             _actionChip(Icons.flash_on, "Döyüş", () => _handleFamilyInteraction(widget.person, "physical_fight"), isNegative: true),

           _actionChip(Icons.sports_esports_outlined, "Oyun oyna", () => _playBoardGame(widget.person)),
        ],
      )
    );
  }

  bool _isFather(FamilyMember member) {
    final relation = member.relation.toLowerCase();
    return relation.contains("ata");
  }

  bool _isSibling(FamilyMember member) {
    final rel = member.relation.toLowerCase();
    return rel.contains("qardaş") || rel.contains("bacı") || rel.contains("qardas") || rel.contains("baci");
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
                        _profileRow("İş", member.job),
                        _profileRow("Aylıq gəlir", "${member.monthlyIncome} AZN"),
                        _profileRow("Xəstəlik", member.diseases.isEmpty ? "Yoxdur" : member.diseases.join(", ")),
                        const SizedBox(height: 10),
                        _statBar("Münasibət", member.relationship, Colors.green),
                        _statBar("Görünüş",   member.looks,         Colors.orange),
                        _statBar("Sağlamlıq", member.health,        Colors.redAccent),
                        _statBar("Gəlir səviyyəsi", _monthlyIncomePercent(member), Colors.green),
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

  int _monthlyIncomePercent(FamilyMember member) {
    final int byIncome = _incomePercentByAmount(member.monthlyIncome);
    final int byJobCap = _incomePercentCapByJob(member.job);
    return min(byIncome, byJobCap);
  }

  int _incomePercentByAmount(int income) {
    if (income <= 500) return 20;
    if (income <= 800) return 35;
    if (income <= 1000) return 45;
    if (income <= 1500) return 65;
    if (income <= 2000) return 70;
    if (income <= 3000) return 80;
    if (income <= 5000) return 90;
    return 100;
  }

  int _incomePercentCapByJob(String job) {
    final normalized = job.toLowerCase();

    if (normalized.contains("satıcı") || normalized.contains("satici")) return 35;
    if (normalized.contains("fəhlə") || normalized.contains("fehle")) return 35;
    if (normalized.contains("müəllim") || normalized.contains("muellim")) return 45;
    if (normalized.contains("ofis")) return 65;
    if (normalized.contains("sürücü") || normalized.contains("surucu")) return 65;
    if (normalized.contains("həkim") || normalized.contains("hekim")) return 80;
    if (normalized.contains("mühəndis") || normalized.contains("muhendis")) return 80;
    if (normalized.contains("biznesmen")) return 90;

    return 100;
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
          side: BorderSide(color: isNegative ? Colors.red.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2)),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  void _addHistory(
    FamilyMember member,
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

    final effectsText = effects.isEmpty ? "" : " (${effects.join(", ")})";
    member.interactionHistory.insert(0, "[Yaş ${widget.player.age}] $message$effectsText");

    if (member.interactionHistory.length > 40) {
      member.interactionHistory.removeRange(40, member.interactionHistory.length);
    }
  }

  void _handleFamilyInteraction(FamilyMember member, String type) {
    if (widget.eventsData == null) return;
    
    String logMsg = "";
    String resultText = "";
    final playerAge = widget.player.age;

    setState(() {
      if (type == "conversation" || type == "spendTime") {
        List<dynamic> allEvents = widget.eventsData!['parents'][type];
        
        final validEvents = allEvents.where((e) {
          // Issue #1: If age key is missing, default to 13+ for safety.
          final minAge = e['minAge'] ?? 13; 
          final maxAge = e['maxAge'] ?? 99;
          return playerAge >= minAge && playerAge <= maxAge;
        }).toList();

        if (validEvents.isEmpty) {
           _showResultDialog("Diqqət", "Bu yaşda ${member.relation} ilə bu cür münasibət üçün uyğun mövzu tapılmadı.");
           return;
        }
        
        var event = validEvents[_random.nextInt(validEvents.length)];
        
        resultText = event['text']
            .replaceAll("Atanla", "${member.relation}nla")
            .replaceAll("Ananla", "${member.relation}nla")
            .replaceAll("Atanın", "${member.relation}nın")
            .replaceAll("Ananın", "${member.relation}nın");
        
        Map<String, dynamic> effects = event['effects'];
        final double relMult = member.relationship < 40 ? 0.35 : 1.0; // Task 13: diminished returns
        if (effects.containsKey('happiness')) {
          final raw = effects['happiness'] as int;
          final scaled = raw > 0 ? (raw * relMult).round() : raw;
          widget.player.happiness = (widget.player.happiness + scaled).clamp(0, 100);
        }
        if (effects.containsKey('relationship')) {
          final raw = effects['relationship'] as int;
          final scaled = raw > 0 ? (raw * relMult).round() : raw;
          member.relationship = (member.relationship + scaled).clamp(0, 100);
        }
        
        logMsg = resultText;
        _addHistory(
          member,
          resultText,
          relationshipDelta: effects['relationship'] is int ? effects['relationship'] as int : null,
          happinessDelta: effects['happiness'] is int ? effects['happiness'] as int : null,
        );
        _showResultDialog(type == "conversation" ? "Söhbət" : "Vaxt Keçirmək", resultText);
      } else if (type == "gift") {
        if (widget.player.money >= 20) {
          widget.player.money -= 20;
          final double giftMult = member.relationship < 40 ? 0.35 : 1.0;
          final int giftBoost = (15 * giftMult).round();
          member.relationship = (member.relationship + giftBoost).clamp(0, 100);
          logMsg = "${member.relation} hədiyyəni çox bəyəndi.";
          _addHistory(member, logMsg, relationshipDelta: 15, moneyDelta: -20);
          _showResultDialog("Hədiyyə", logMsg);
        } else {
          _addHistory(member, "Hədiyyə almaq üçün kifayət qədər pul olmadı.");
          _showResultDialog("Xəta", "Hədiyyə almaq üçün kifayət qədər pulun yoxdur!");
          return;
        }
      } else if (type == "ask_money") {
        if (member.askedMoneyThisYear) {
          _addHistory(member, "Bu il yenidən pul istəndi, amma limit dolub.");
          _showResultDialog("Diqqət", "Bu il artıq ${member.relation}-dan pul istəmisən.");
          return;
        }
        member.askedMoneyThisYear = true;

        // Father refuses to give money if relationship is too low
        if (_isFather(member) && member.relationship < 30) {
          member.relationship = (member.relationship - 5).clamp(0, 100);
          logMsg = "${member.relation} acıqlı bir tonda 'Sənə veriləcək pulum yoxdur!' dedi.";
          _addHistory(member, logMsg, relationshipDelta: -5);
          _showResultDialog("Rədd edildi", logMsg);
        } else {
          double chance = (member.relationship * 0.4) + (member.generosity * 0.4) + ((member.totalMoney / 10000) * 20);
          if (_random.nextInt(100) < chance) {
            int amount = 5 + _random.nextInt(25);
            if (member.totalMoney < amount) amount = member.totalMoney;
            widget.player.money += amount;
            member.totalMoney -= amount;
            logMsg = "${member.relation} sənə $amount AZN verdi.";
            _addHistory(member, logMsg, moneyDelta: amount);
            _showResultDialog("Pul istə", logMsg);
          } else {
            member.relationship = (member.relationship - 5).clamp(0, 100);
            logMsg = "${member.relation} sənə pul verməkdən imtina etdi.";
            _addHistory(member, logMsg, relationshipDelta: -5);
            _showResultDialog("Rədd edildi", logMsg);
          }
        }
      } else if (type == "argue") {
        List<dynamic> allFightEvents = widget.eventsData!['parents']['fight'];
        
        final validFightEvents = allFightEvents.where((e) {
          // STRICT FILTERING: 
          // If minAge is missing, default to 12 for fights per Issue #1
          final minAge = e['minAge'] ?? 12;
          final maxAge = e['maxAge'] ?? 99;
          return playerAge >= minAge && playerAge <= maxAge;
        }).toList();

        if (validFightEvents.isEmpty) {
           _showResultDialog("Diqqət", "Bu yaşda ciddi mübahisə mövzusu tapılmadı.");
           return;
        }

        var event = validFightEvents[_random.nextInt(validFightEvents.length)];
        resultText = event['text']
            .replaceAll("Atanla", "${member.relation}nla")
            .replaceAll("Ananla", "${member.relation}nla");

        member.relationship = (member.relationship - 15).clamp(0, 100);
        widget.player.happiness = (widget.player.happiness - 10).clamp(0, 100);
        
        logMsg = resultText;

        // If father and relationship is very low, he might hit you after an argument
        if (_isFather(member) && member.relationship < 15 && _random.nextInt(100) < 40) {
          widget.player.health = (widget.player.health - 20).clamp(0, 100);
          logMsg += "\n\n${member.relation} çox qəzəbləndi və sənə şillə vurdu!";
          _addHistory(member, logMsg, relationshipDelta: -15, happinessDelta: -10, healthDelta: -20);
        } else {
          _addHistory(member, logMsg, relationshipDelta: -15, happinessDelta: -10);
        }
        
        _showResultDialog("Mübahisə", logMsg);
      } else if (type == "physical_fight") {
        // Severe escalation for low relationship
        member.relationship = (member.relationship - 30).clamp(0, 100);
        widget.player.health = (widget.player.health - 35).clamp(0, 100);
        widget.player.happiness = (widget.player.happiness - 25).clamp(0, 100);
        
        logMsg = "${member.relation} ilə əlbəyaxa dava etdin. O səni bərk döydü və evdən qovmaqla hədələdi.";
        _addHistory(member, logMsg, relationshipDelta: -30, healthDelta: -35, happinessDelta: -25);
        _showResultDialog("Döyüş", logMsg);
      }
      
      if (logMsg.isNotEmpty) widget.onAction(logMsg);
    });
  }

  Future<void> _playBoardGame(FamilyMember member) async {
    final result = await Navigator.push<MiniGameResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MiniGamesScreen(personName: member.relation),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      member.relationship = (member.relationship + result.relationshipDelta).clamp(0, 100);
      widget.player.happiness = (widget.player.happiness + result.happinessDelta).clamp(0, 100);
      _addHistory(
        member,
        result.logMessage,
        relationshipDelta: result.relationshipDelta,
        happinessDelta: result.happinessDelta,
      );
      widget.onAction(result.logMessage);
    });

    _showResultDialog(
      "Oyun: ${result.gameName}",
      "${result.logMessage}\n\nMünasibət: ${result.relationshipDelta > 0 ? '+' : ''}${result.relationshipDelta}\nXoşbəxtlik: ${result.happinessDelta > 0 ? '+' : ''}${result.happinessDelta}",
    );
  }
}
