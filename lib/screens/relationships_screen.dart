import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/player.dart';
import 'person_interaction_screen.dart';

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
      final String response = await rootBundle.loadString('assets/relationship_events.json');
      setState(() {
        _eventsData = json.decode(response);
      });
    } catch (e) {
      debugPrint("Error loading relationship events: $e");
    }
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
        return _buildPersonCard(member, member.relation, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PersonInteractionScreen(
            player: widget.player, 
            person: member, 
            onAction: widget.onAction, 
            eventsData: _eventsData
          ))).then((_) => setState(() {})); // Refresh when coming back
        });
      },
    );
  }

  Widget _buildFriendList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.player.friends.length,
      itemBuilder: (context, index) {
        final friend = widget.player.friends[index];
        return _buildPersonCard(friend, "Dost", () {
          // Navigation for friends can be added here later if needed
        });
      },
    );
  }

  Widget _buildPersonCard(Person person, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(person.gender == Gender.male ? Icons.face : Icons.face_3, color: Colors.blueAccent),
        ),
        title: Text("${person.name} ${person.surname}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: person.relationship / 100,
                  minHeight: 4,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    person.relationship > 70 ? Colors.green : 
                    person.relationship > 30 ? Colors.blueAccent : Colors.redAccent
                  ),
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
