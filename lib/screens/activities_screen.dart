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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Fəaliyyətlər", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: availableActivities.isEmpty
          ? const Center(child: Text("Hələ çox balacasan."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableActivities.length,
              itemBuilder: (context, index) {
                final activity = availableActivities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                  color: activity.isSchoolActivity ? Colors.orange[50] : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activity.isSchoolActivity ? Colors.orange.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(activity.icon, color: activity.isSchoolActivity ? Colors.orange : Colors.blueAccent),
                    ),
                    title: Row(
                      children: [
                        Text(activity.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (activity.isSchoolActivity)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.school, size: 14, color: Colors.orange),
                          ),
                      ],
                    ),
                    subtitle: Text(activity.description),
                    trailing: Text(
                      activity.cost > 0 ? "${activity.cost} AZN" : "Pulsuz",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
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
                  ),
                );
              },
            ),
    );
  }
}
