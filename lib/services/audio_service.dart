import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _audioPlayer;

  /// Reproduz o som de comemoração
  Future<void> playCelebrationSound() async {
    try {
      // Cria um novo player para cada reprodução
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.play(AssetSource('sounds/applause_cheer.mp3'));
      
      // Libera o player após a reprodução
      _audioPlayer!.onPlayerComplete.listen((_) {
        _audioPlayer?.dispose();
        _audioPlayer = null;
      });
    } catch (e) {
      print('Erro ao reproduzir som de comemoração: $e');
      _audioPlayer?.dispose();
      _audioPlayer = null;
    }
  }

  /// Para qualquer som que esteja sendo reproduzido
  Future<void> stop() async {
    try {
      await _audioPlayer?.stop();
      _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch (e) {
      print('Erro ao parar reprodução de áudio: $e');
    }
  }

  /// Libera os recursos do player
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}