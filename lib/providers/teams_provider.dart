import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';

class TeamsNotifier extends ChangeNotifier {
  static const String _boxName = 'teams';
  late Box<Team> _teamsBox;
  Map<String, Team> _teams = {};
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;

  TeamsNotifier() {
    _init();
  }

  Map<String, Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _initHive();
      _teams = _loadTeams();
      _isLoading = false;
      _error = null;
      _isInitialized = true;
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
  Future<Team> createTeam([
    String? name,
    List<String>? members,
    String? emoji,
    String? imagePath,
    Color? color,
  ]) async {
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

  // Create a new team with named parameters
  Future<Team> createTeamWithParams({
    String? name,
    List<String>? members,
    String? emoji,
    String? imagePath,
    Color? color,
  }) async {
    return createTeam(name, members, emoji, imagePath, color);
  }

  // Update an existing team
  Future<void> updateTeam(
    dynamic teamOrId, {
    String? name,
    List<String>? members,
    String? emoji,
    String? imagePath,
    Color? color,
  }) async {
    Team team;
    
    if (teamOrId is Team) {
      team = teamOrId;
    } else if (teamOrId is String) {
      final existingTeam = _teams[teamOrId];
      if (existingTeam == null) return;
      
      team = existingTeam.copyWith(
        name: name,
        members: members,
        emoji: emoji,
        imagePath: imagePath,
        color: color,
      );
    } else {
      return;
    }
    
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

  // Search teams by name
  List<Team> searchTeams(String query) {
    if (query.isEmpty) return getAllTeams();
    
    final lowerQuery = query.toLowerCase();
    return _teams.values
        .where((team) => team.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Get teams by color
  List<Team> getTeamsByColor(Color color) {
    return _teams.values
        .where((team) => team.color.value == color.value)
        .toList();
  }

  // Add win to a team
  Future<void> addWin(String teamId, [String? tournamentId]) async {
    final team = _teams[teamId];
    if (team == null) return;
    
    team.addWin(tournamentId);
    await _teamsBox.put(teamId, team);
    _teams[teamId] = team;
    notifyListeners();
  }

  // Add loss to a team
  Future<void> addLoss(String teamId, [String? tournamentId]) async {
    final team = _teams[teamId];
    if (team == null) return;
    
    team.addLoss(tournamentId);
    await _teamsBox.put(teamId, team);
    _teams[teamId] = team;
    notifyListeners();
  }

  // Get top teams by wins
  List<Team> getTopTeams(int limit) {
    final teams = getAllTeams();
    teams.sort((a, b) {
      // Sort by wins first, then by win rate
      final winsComparison = b.wins.compareTo(a.wins);
      if (winsComparison != 0) return winsComparison;
      return b.winRate.compareTo(a.winRate);
    });
    
    return teams.take(limit).toList();
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
