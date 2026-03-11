import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import 'game_screen.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  Gender _selectedGender = Gender.male;
  String _selectedCity = "Bakı";

  final Map<String, int> _locationRichness = {
    "İçərişəhər": 10, "Sahil": 10, "Ağ Şəhər": 10, "Bilgəh": 10, "Mərdəkan": 10,
    "Gənclik": 9, "28 May": 9, "Badamdar": 9, "N. Nərimanov": 8, "Elmlər Akademiyası": 8,
    "Buzovna": 8, "Şüvəlan": 8, "Bayıl": 7, "Bibiheybət": 7, "Xətai": 7, "Nizami": 7,
    "Bakıxanov": 7, "Əhmədli": 6, "H. Aslanov": 6, "Qaraçuxur": 6, "Yeni Suraxanı": 5,
    "20 Yanvar": 5, "Memar Əcəmi": 5, "Nəsimi": 5, "Azadlıq": 5, "Q. Qarayev": 5,
    "Neftçilər": 5, "Xalqlar Dostluğu": 5, "Sabunçu": 4, "Zabrat": 4, "Ramana": 4,
    "Bülbülə": 4, "Keşlə": 4, "Biləcəri": 4, "Binə": 4, "Maştağa": 4, "Pirşağı": 4,
    "Nardaran": 4, "Hövsan": 4, "Koroğlu": 3, "Ulduz": 3, "Bakmil": 3, "C. Cabbarlı": 3,
    "İnşaatçılar": 3, "Dərnəgül": 3, "Lökbatan": 3, "Qızıldaş": 2, "Ələt": 2,
    "Baş Ələt": 2, "Yeni Ələt": 2, "Gürgən": 2, "Pirsaat": 2, "Puta": 2, "Şonqar": 2,
    "Şubanı": 2, "Türkan": 2, "Zirə": 2, "Qala": 2, "Çeyildağ": 1, "Heybət": 1,
    "Korgöz": 1, "Kotal": 1, "Kürdəxanı": 1, "Qarakosa": 1, "Şanxay": 1, "Şıxlar": 1,
    "Zığ": 1, "İliç buxtası": 1, "Neft Daşları": 1, "Müşfiqabad": 1, "Balaxanı": 1,
    "Əmircan": 1, "Bakı": 5, "Gəncə": 5, "Sumqayıt": 5, "Lənkəran": 4, "Şəki": 4,
    "Naxçıvan": 5, "Qəbələ": 6, "Şuşa": 6
  };

  void _onStartLife() {
    if (_nameController.text.trim().isEmpty || _surnameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zəhmət olmasa ad və soyadınızı daxil edin")),
      );
      return;
    }

    int richnessScore = _locationRichness[_selectedCity] ?? 5;
    // Smarts calculation based on richness (Base smarts + richness factor)
    int baseSmarts = 30 + Random().nextInt(40); // 30-70 random
    int finalSmarts = (baseSmarts + (richnessScore * 3)).clamp(0, 100);

    final player = Player(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      gender: _selectedGender,
      birthCity: _selectedCity,
      smarts: finalSmarts,
      imageVariant: Random().nextInt(100),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(player: player)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedLocations = _locationRichness.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 60, 0, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
            ),
            child: Column(
              children: const [
                Text("🇦🇿", style: TextStyle(fontSize: 52)),
                SizedBox(height: 10),
                Text(
                  "AzLife",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                ),
                SizedBox(height: 4),
                Text(
                  "Yeni Həyata Başla",
                  style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          // ── Form ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField(_nameController, "Ad"),
                  const SizedBox(height: 16),
                  _buildField(_surnameController, "Soyad"),
                  const SizedBox(height: 28),

                  _sectionLabel("Cinsiyyət"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _genderOption("👦  Kişi",  Gender.male),
                      const SizedBox(width: 12),
                      _genderOption("👧  Qadın", Gender.female),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _sectionLabel("Doğulduğun yer"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1565C0)),
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                        items: sortedLocations
                            .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCity = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _onStartLife,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EC95C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "HƏYATA BAŞLA",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF888888), letterSpacing: 0.5));
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _genderOption(String label, Gender gender) {
    final selected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1565C0) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF1565C0) : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }
}
