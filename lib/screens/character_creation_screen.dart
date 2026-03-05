import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import 'loading_screen.dart';
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
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          onFinished: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GameScreen(player: player)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedLocations = _locationRichness.keys.toList()..sort();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Yeni Həyat", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_nameController, "Ad", Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_surnameController, "Soyad", Icons.family_restroom_outlined),
            const SizedBox(height: 24),
            const Text("Cinsiyyət", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _genderOption("Kişi", Gender.male, Icons.male),
                const SizedBox(width: 16),
                _genderOption("Qadın", Gender.female, Icons.female),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Doğulduğunuz yer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCity,
                  isExpanded: true,
                  items: sortedLocations.map((loc) {
                    return DropdownMenuItem(value: loc, child: Text(loc));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCity = val!),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _onStartLife,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("HƏYATA BAŞLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  Widget _genderOption(String title, Gender gender, IconData icon) {
    bool isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
