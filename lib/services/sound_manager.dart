import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSound(String fileName) async {
    try {
      // For audioplayers ^5.2.1, AssetSource starts FROM the root of the 'assets' folder defined in pubspec.
      // After moving files to root assets folder, use this path:
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  static void playAgeUp() => playSound('age_up.mp3');
  static void playClick() => playSound('other_buttons.mp3');
  static void playSuccess() => playSound('success.mp3');
  static void playFail() => playSound('fail.mp3');
  static void playBabyBorn() => playSound('baby_born.mp3');
}
