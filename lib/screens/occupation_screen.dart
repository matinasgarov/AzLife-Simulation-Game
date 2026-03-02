import 'package:flutter/material.dart';
import '../models/player.dart';

class OccupationScreen extends StatefulWidget {
  final Player player;
  final Function(String) onAction;

  const OccupationScreen({super.key, required this.player, required this.onAction});

  @override
  State<OccupationScreen> createState() => _OccupationScreenState();
}

class _OccupationScreenState extends State<OccupationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Məktəb Həyatı", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSchoolStats(),
            const SizedBox(height: 30),
            _buildActionCard(
              title: "Dərslərinə Çalış",
              description: "Gecəni gündüzünə qat və gələcəyini qur. Qiymətlərin 10% artacaq.",
              icon: Icons.menu_book,
              color: Colors.green,
              onTap: () {
                setState(() {
                  widget.player.studiedHardThisYear = true;
                  widget.player.skippedSchoolThisYear = false;
                });
                widget.onAction("Sən bu il dərslərinə çox ciddi çalışmaq qərarına gəldin.");
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 15),
            _buildActionCard(
              title: "Dərsdən Qaç",
              description: "Dərs kimə lazımdır? Get dostlarınla vaxt keçir. Qiymətlərin 10% düşəcək.",
              icon: Icons.directions_run,
              color: Colors.redAccent,
              onTap: () {
                setState(() {
                  widget.player.skippedSchoolThisYear = true;
                  widget.player.studiedHardThisYear = false;
                });
                widget.onAction("Sən bu il dərsləri boş vermək və vaxtını əyləncəyə ayırmaq qərarına gəldin.");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _statRow("Qiymətlər", widget.player.grades / 100, Colors.orange),
          const SizedBox(height: 15),
          _statRow("Populyarlıq", widget.player.schoolPopularity / 100, Colors.purple),
          const SizedBox(height: 15),
          _statRow("Aktivlik", widget.player.schoolActivity / 100, Colors.blue),
        ],
      ),
    );
  }

  Widget _statRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 12,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
