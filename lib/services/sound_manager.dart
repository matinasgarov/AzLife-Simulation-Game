import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSound(String fileName) async {
    try {
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  static void playAgeUp() => playSound('age_up.mp3');
  static void playClick() => playSound('other_buttons.mp3');
  static void playSuccess() => playSound('success.mp3');
  static void playFail() => playSound('fail.mp3');
  static void playBabyBorn() => playSound('baby_born.mp3');
}
