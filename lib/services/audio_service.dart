import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Reproduz o som de comemoração
  Future<void> playCelebrationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/applause_cheer.mp3'));
    } catch (e) {
      print('Erro ao reproduzir som de comemoração: $e');
    }
  }

  /// Para qualquer som que esteja sendo reproduzido
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Erro ao parar reprodução de áudio: $e');
    }
  }

  /// Libera os recursos do player
  void dispose() {
    _audioPlayer.dispose();
  }
}