import 'package:flutter/material.dart';
import '../models/player.dart';
import 'mini_games_screen.dart';
import 'wedding_planner_screen.dart';

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
          p.smarts = (p.smarts + 3).clamp(0, 100); // nerfed: was +8
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
          p.smarts = (p.smarts + 4).clamp(0, 100); // nerfed: was +10
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

    // Find fiancée (if any) for wedding section
    final fiance = player.friends.cast<SchoolMate?>().firstWhere(
      (f) => f!.relationType == FriendRelationType.partner && f.partnerStatus == PartnerStatus.fiance,
      orElse: () => null,
    );

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
                if (fiance != null) ...[
                  _sectionHeader("Toy", color: const Color(0xFFC0185A), icon: Icons.diamond),
                  _weddingRow(context, fiance),
                ],
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

  Widget _sectionHeader(String title, {Color color = const Color(0xFF555555), IconData? icon}) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
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

  Widget _weddingRow(BuildContext context, SchoolMate fiance) {
    final isPlanned = fiance.weddingPlanStatus == "planned";
    return InkWell(
      onTap: () async {
        if (isPlanned) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Toy planı", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(
                "Nişanlı: ${fiance.name}\nYer: ${fiance.weddingVenue}\nTarix: ${fiance.weddingScheduledAge} yaşında\nÜmumi xərc: ${fiance.weddingTotalCost} AZN",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Bağla"),
                ),
              ],
            ),
          );
          return;
        }
        final confirmed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => WeddingPlannerScreen(player: player, partner: fiance),
          ),
        );
        if (confirmed == true && context.mounted) {
          onActivityPerformed("Toy planlaşdırıldı: ${fiance.weddingVenue}, ${fiance.weddingScheduledAge} yaşında");
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Icon(
              isPlanned ? Icons.event_available : Icons.diamond_outlined,
              size: 26,
              color: const Color(0xFFC0185A),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlanned ? "Toy məlumatı" : "Toyu planlaşdır",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPlanned
                        ? "${fiance.weddingVenue} · ${fiance.weddingScheduledAge} yaşında · ${fiance.weddingTotalCost} AZN"
                        : "${fiance.name} ilə toyun yerini, qonaqlarını və tarixini planlaşdır.",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isPlanned ? "Planlaşdırılıb" : "Pulsuz",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isPlanned ? const Color(0xFFC0185A) : const Color(0xFF2EC95C),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(BuildContext context, Activity activity) {
    return InkWell(
      onTap: () async {
        if (player.money < activity.cost) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pulun yoxdur!")),
          );
          return;
        }
        // Çayxana launches mini-games sub-menu (Task 9)
        if (activity.name == "Çayxana") {
          activity.onPerform(player); // deduct cost + apply happiness
          final result = await Navigator.push<MiniGameResult>(
            context,
            MaterialPageRoute(builder: (_) => const MiniGamesScreen(personName: "Çayxana Dostu")),
          );
          if (result != null) {
            onActivityPerformed("Çayxana – ${result.gameName}: ${result.logMessage}");
          } else {
            onActivityPerformed("Fəaliyyət: ${activity.name}");
          }
          if (context.mounted) Navigator.pop(context);
          return;
        }
        activity.onPerform(player);
        onActivityPerformed("Fəaliyyət: ${activity.name}");
        Navigator.pop(context);
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
