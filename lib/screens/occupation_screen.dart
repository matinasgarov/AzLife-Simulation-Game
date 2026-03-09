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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("MƏKTƏB HƏYATI", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _sectionBand("Seçimlər"),
          _actionRow(
            title: "Dərslərinə Çalış",
            description: "Gecəni gündüzünə qat və gələcəyini qur. Qiymətlərin 10% artacaq.",
            icon: Icons.menu_book,
            iconColor: const Color(0xFF2EC95C),
            onTap: () {
              widget.player.studiedHardThisYear = true;
              widget.player.skippedSchoolThisYear = false;
              widget.onAction("Sən bu il dərslərinə çox ciddi çalışmaq qərarına gəldin.");
              Navigator.pop(context);
            },
          ),
          _actionRow(
            title: "Dərsdən Qaç",
            description: "Dərs kimə lazımdır? Get dostlarınla vaxt keçir. Qiymətlərin 10% düşəcək.",
            icon: Icons.directions_run,
            iconColor: const Color(0xFFFF6B6B),
            onTap: () {
              widget.player.skippedSchoolThisYear = true;
              widget.player.studiedHardThisYear = false;
              widget.onAction("Sən bu il dərsləri boş vermək və vaxtını əyləncəyə ayırmaq qərarına gəldin.");
              Navigator.pop(context);
            },
          ),
          _sectionBand("Statistika"),
          _statsBlock(),
        ],
      ),
    );
  }

  Widget _sectionBand(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF555555),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
      ),
    );
  }

  Widget _statsBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          _statRow(Icons.menu_book, "Qiymətlər", widget.player.grades.toInt(), const Color(0xFFE67E22)),
          const SizedBox(height: 12),
          _statRow(Icons.star, "Populyarlıq", widget.player.schoolPopularity.toInt(), const Color(0xFF9B59B6)),
          const SizedBox(height: 12),
          _statRow(Icons.directions_run, "Aktivlik", widget.player.schoolActivity.toInt(), const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, int value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text("$value%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
        ),
      ],
    );
  }

  Widget _actionRow({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 3),
                  Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
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
