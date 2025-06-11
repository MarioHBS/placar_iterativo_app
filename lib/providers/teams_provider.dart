import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';

class TeamsNotifier extends ChangeNotifier {
  static const String _boxName = 'teams';
  late Box<Team> _teamsBox;
  Map<String, Team> _teams = {};
  bool _isLoading = true;
  String? _error;

  TeamsNotifier() {
    _init();
  }

  Map<String, Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    try {
      await _initHive();
      _teams = _loadTeams();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> _initHive() async {
    _teamsBox = await Hive.openBox<Team>(_boxName);
  }

  Map<String, Team> _loadTeams() {
    final teams = <String, Team>{};
    for (final key in _teamsBox.keys) {
      final team = _teamsBox.get(key);
      if (team != null) {
        teams[key.toString()] = team;
      }
    }
    return teams;
  }

  // Create a new team
  Future<Team> createTeam({
    String? name,
    List<String>? members,
    String? emoji,
    String? imagePath,
    Color? color,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final team = Team(
      id: id,
      name: name ?? 'Equipe $id',
      members: members ?? [],
      emoji: emoji,
      imagePath: imagePath,
      color: color ?? Colors.blue,
    );

    await _teamsBox.put(id, team);
    _teams[id] = team;
    notifyListeners();
    return team;
  }

  // Update an existing team
  Future<void> updateTeam(Team team) async {
    await _teamsBox.put(team.id, team);
    _teams[team.id] = team;
    notifyListeners();
  }

  // Delete a team
  Future<void> deleteTeam(String id) async {
    await _teamsBox.delete(id);
    _teams.remove(id);
    notifyListeners();
  }

  // Get a team by ID
  Team? getTeam(String id) {
    return _teams[id];
  }

  // Get all teams as a list
  List<Team> getAllTeams() {
    return _teams.values.toList();
  }

  // Reset all team stats
  Future<void> resetAllTeamStats() async {
    for (final team in _teams.values) {
      team.resetStats();
      await _teamsBox.put(team.id, team);
    }
    notifyListeners();
  }

  // Reload teams from Hive (useful after import operations)
  Future<void> reloadTeams() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _teams = _loadTeams();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }
}
