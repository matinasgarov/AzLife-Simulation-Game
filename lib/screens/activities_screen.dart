import 'package:flutter/material.dart';
import '../models/player.dart';

class Activity {
  final String name;
  final String description;
  final IconData icon;
  final int cost;
  final int minAge;
  final bool isSchoolActivity;
  final Function(Player) onPerform;

  Activity({
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.minAge,
    this.isSchoolActivity = false,
    required this.onPerform,
  });
}

class ActivitiesScreen extends StatelessWidget {
  final Player player;
  final Function(String) onActivityPerformed;

  const ActivitiesScreen({
    super.key,
    required this.player,
    required this.onActivityPerformed,
  });

  @override
  Widget build(BuildContext context) {
    final List<Activity> allActivities = [
      // School Activities
      Activity(
        name: "Azfar-da Futbol",
        description: "Sinif yoldaşlarınla Azfar meydançasında qırğın futbol oyna.",
        icon: Icons.sports_soccer,
        cost: 5,
        minAge: 7,
        isSchoolActivity: true,
        onPerform: (p) {
          p.health = (p.health + 10).clamp(0, 100);
          p.happiness = (p.happiness + 15).clamp(0, 100);
          p.schoolPopularity = (p.schoolPopularity + 5).clamp(0, 100);
          p.money -= 5;
        },
      ),
      Activity(
        name: "Bufet-də Hot-doq",
        description: "Məktəb bufetində şübhəli, amma dadlı hot-doq ye.",
        icon: Icons.fastfood,
        cost: 2,
        minAge: 7,
        isSchoolActivity: true,
        onPerform: (p) {
          p.happiness = (p.happiness + 8).clamp(0, 100);
          p.health = (p.health - 5).clamp(0, 100);
          p.money -= 2;
        },
      ),
      // Regular Activities
      Activity(
        name: "İdman Zalı",
        description: "Sağlamlığını və görünüşünü yaxşılaşdır.",
        icon: Icons.fitness_center,
        cost: 20,
        minAge: 16,
        onPerform: (p) {
          p.health = (p.health + 10).clamp(0, 100);
          p.looks = (p.looks + 5).clamp(0, 100);
          p.money -= 20;
        },
      ),
      Activity(
        name: "Muzeyə Baş Çək",
        description: "Tariximizi və mədəniyyətimizi öyrən.",
        icon: Icons.museum,
        cost: 10,
        minAge: 7,
        onPerform: (p) {
          p.smarts = (p.smarts + 8).clamp(0, 100);
          p.happiness = (p.happiness + 5).clamp(0, 100);
          p.money -= 10;
        },
      ),
      Activity(
        name: "Çayxana",
        description: "Nərd üzrə qrosmeyster olduğunu sübut et.",
        icon: Icons.coffee,
        cost: 5,
        minAge: 15,
        onPerform: (p) {
          p.happiness = (p.happiness + 12).clamp(0, 100);
          p.money -= 5;
        },
      ),
      Activity(
        name: "Kinoya Get",
        description: "Ən son Azərbaycan filmlərinə bax.",
        icon: Icons.movie,
        cost: 15,
        minAge: 10,
        onPerform: (p) {
          p.happiness = (p.happiness + 10).clamp(0, 100);
          p.money -= 15;
        },
      ),
      Activity(
        name: "Kitabxana",
        description: "Ağıllı görünmək üçün kitab oxu.",
        icon: Icons.menu_book,
        cost: 0,
        minAge: 13,
        onPerform: (p) {
          p.smarts = (p.smarts + 10).clamp(0, 100);
          p.happiness -= 2;
        },
      ),
      Activity(
        name: "Bulvarda Gəzinti",
        description: "Dəniz kənarında gəz və Alov Qüllələrinə bax.",
        icon: Icons.directions_walk,
        cost: 0,
        minAge: 7,
        onPerform: (p) {
          p.happiness = (p.happiness + 8).clamp(0, 100);
          p.health = (p.health + 2).clamp(0, 100);
        },
      ),
    ];

    final availableActivities = allActivities.where((a) => player.age >= a.minAge).toList();

    final schoolActivities  = availableActivities.where((a) =>  a.isSchoolActivity).toList();
    final generalActivities = availableActivities.where((a) => !a.isSchoolActivity).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("FƏALİYYƏTLƏR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: availableActivities.isEmpty
          ? const Center(child: Text("Hələ çox balacasan.", style: TextStyle(color: Color(0xFF888888))))
          : ListView(
              children: [
                if (schoolActivities.isNotEmpty) ...[
                  _sectionHeader("Məktəb"),
                  ...schoolActivities.map((a) => _activityRow(context, a)),
                ],
                if (generalActivities.isNotEmpty) ...[
                  _sectionHeader("Ümumi"),
                  ...generalActivities.map((a) => _activityRow(context, a)),
                ],
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
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

  Widget _activityRow(BuildContext context, Activity activity) {
    return InkWell(
      onTap: () {
        if (player.money >= activity.cost) {
          activity.onPerform(player);
          onActivityPerformed("Fəaliyyət: ${activity.name}");
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pulun yoxdur!")),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Icon(activity.icon, size: 26, color: activity.isSchoolActivity ? const Color(0xFFE67E22) : const Color(0xFF1565C0)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(activity.description, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              activity.cost > 0 ? "${activity.cost} AZN" : "Pulsuz",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: activity.cost > 0 ? const Color(0xFF1565C0) : const Color(0xFF2EC95C),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}
