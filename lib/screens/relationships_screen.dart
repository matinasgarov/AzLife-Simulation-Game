import 'package:flutter/material.dart';
import '../models/player.dart';

class RelationshipsScreen extends StatefulWidget {
  final Player player;
  const RelationshipsScreen({super.key, required this.player});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text("Münasibətlər", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: widget.player.family.isEmpty
          ? const Center(child: Text("Heç bir yaxın qohumun yoxdur."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.player.family.length,
              itemBuilder: (context, index) {
                final member = widget.player.family[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        member.relation == "Ata" ? Icons.man : Icons.woman,
                        color: Colors.blueAccent,
                      ),
                    ),
                    title: Text("${member.name} (${member.relation})",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: member.relationship / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[100],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text("${member.relationship}%",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onTap: () {
                      _showInteractionDialog(member);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showInteractionDialog(FamilyMember member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${member.name} ilə nə etmək istəyirsən?",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text("Söhbət et"),
                onTap: () {
                  setState(() {
                    member.relationship = (member.relationship + 5).clamp(0, 100);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text("Hədiyyə ver (10 AZN)"),
                onTap: () {
                  if (widget.player.money >= 10) {
                    setState(() {
                      widget.player.money -= 10;
                      member.relationship = (member.relationship + 15).clamp(0, 100);
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Kifayət qədər pulun yoxdur!")),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
