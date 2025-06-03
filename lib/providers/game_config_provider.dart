import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/game_config.dart';

class GameConfigNotifier extends ChangeNotifier {
  static const String _boxName = 'game_configs';
  late Box<GameConfig> _configsBox;
  Map<String, GameConfig> _configs = {};
  bool _isLoading = true;
  String? _error;

  GameConfigNotifier() {
    _init();
  }

  Map<String, GameConfig> get configs => _configs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    try {
      await _initHive();
      _configs = _loadConfigs();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> _initHive() async {
    _configsBox = await Hive.openBox<GameConfig>(_boxName);
  }

  Map<String, GameConfig> _loadConfigs() {
    final configs = <String, GameConfig>{};
    for (final key in _configsBox.keys) {
      final config = _configsBox.get(key);
      if (config != null) {
        configs[key.toString()] = config;
      }
    }
    return configs;
  }

  // Create a free mode config
  Future<GameConfig> createFreeMode() async {
    final config = GameConfig.freeMode();
    await _configsBox.put(config.id, config);
    _configs[config.id] = config;
    notifyListeners();
    return config;
  }

  // Create a tournament mode config
  Future<GameConfig> createTournamentMode({
    required EndCondition endCondition,
    int? timeLimit,
    int? scoreLimit,
    int winsForWaitingMode = 3,
    int? totalMatches,
  }) async {
    final config = GameConfig.tournamentMode(
      endCondition: endCondition,
      timeLimit: timeLimit,
      scoreLimit: scoreLimit,
      winsForWaitingMode: winsForWaitingMode,
      totalMatches: totalMatches,
    );
    await _configsBox.put(config.id, config);
    _configs[config.id] = config;
    notifyListeners();
    return config;
  }

  // Update an existing config
  Future<void> updateConfig(GameConfig config) async {
    await _configsBox.put(config.id, config);
    _configs[config.id] = config;
    notifyListeners();
  }

  // Delete a config
  Future<void> deleteConfig(String id) async {
    await _configsBox.delete(id);
    _configs.remove(id);
    notifyListeners();
  }

  // Get a config by ID
  GameConfig? getConfig(String id) {
    return _configs[id];
  }

  // Get all configs as a list
  List<GameConfig> getAllConfigs() {
    return _configs.values.toList();
  }
}
