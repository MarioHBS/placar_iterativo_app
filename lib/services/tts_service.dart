import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSupported = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verificar se TTS é suportado na plataforma atual
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows)) {
        print('TTS não suportado nesta plataforma');
        _isInitialized = true;
        return;
      }

      _flutterTts = FlutterTts();
      
      // Configurar idioma para português brasileiro
      await _flutterTts!.setLanguage('pt-BR');
      
      // Configurar velocidade da fala
      await _flutterTts!.setSpeechRate(0.6);
      
      // Configurar volume
      await _flutterTts!.setVolume(1.0);
      
      // Configurar pitch
      await _flutterTts!.setPitch(1.0);
      
      _isSupported = true;
      _isInitialized = true;
      print('TTS inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar TTS: $e');
      _isSupported = false;
      _isInitialized = true;
    }
  }

  Future<void> announceScore({
    required String teamAName,
    required int teamAScore,
    required String teamBName,
    required int teamBScore,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isSupported || _flutterTts == null) {
      print('TTS não disponível - Placar: $teamAName $teamAScore x $teamBScore $teamBName');
      return;
    }

    try {
      // Parar qualquer fala em andamento
      await _flutterTts!.stop();
      
      // Criar mensagem do placar
      final message = '$teamAName $teamAScore, $teamBName $teamBScore';
      
      // Falar o placar
      await _flutterTts!.speak(message);
    } catch (e) {
      print('Erro ao anunciar placar: $e');
    }
  }

  Future<void> announceWinner(String teamName) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isSupported || _flutterTts == null) {
      print('TTS não disponível - Vencedor: $teamName');
      return;
    }

    try {
      await _flutterTts!.stop();
      final message = 'Parabéns $teamName! Vocês venceram!';
      await _flutterTts!.speak(message);
    } catch (e) {
      print('Erro ao anunciar vencedor: $e');
    }
  }

  Future<void> announceMatchStart() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isSupported || _flutterTts == null) {
      print('TTS não disponível - Partida iniciada!');
      return;
    }

    try {
      await _flutterTts!.stop();
      const message = 'Partida iniciada! Boa sorte!';
      await _flutterTts!.speak(message);
    } catch (e) {
      print('Erro ao anunciar início da partida: $e');
    }
  }

  Future<void> stop() async {
    if (!_isSupported || _flutterTts == null) {
      return;
    }

    try {
      await _flutterTts!.stop();
    } catch (e) {
      print('Erro ao parar TTS: $e');
    }
  }

  void dispose() {
    if (_isSupported && _flutterTts != null) {
      try {
        _flutterTts!.stop();
      } catch (e) {
        print('Erro ao fazer dispose do TTS: $e');
      }
    }
  }
}