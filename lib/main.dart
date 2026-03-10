import 'package:flutter/material.dart';
import 'screens/character_creation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AzLifeApp());
}

class AzLifeApp extends StatelessWidget {
  const AzLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AzLife',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Roboto', // Standard clean font
      ),
      home: const CharacterCreationScreen(),
    );
  }
}
