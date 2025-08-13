import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';

class MatchesNotifier extends ChangeNotifier {
  static const String _boxName = 'matches';
  late Box<Match> _matchesBox;
  Map<String, Match> _matches = {};
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;

  MatchesNotifier() {
    _init();
  }

  Map<String, Match> get matches => _matches;
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
      _matches = _loadMatches();
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
    _matchesBox = await Hive.openBox<Match>(_boxName);
  }

  Map<String, Match> _loadMatches() {
    final matches = <String, Match>{};
    for (final key in _matchesBox.keys) {
      final match = _matchesBox.get(key);
      if (match != null) {
        matches[key.toString()] = match;
      }
    }
    return matches;
  }

  // Create a new match
  Future<Match> createMatch([
    dynamic teamAOrTeamA,
    dynamic teamBOrTeamB,
    dynamic configOrNull,
  ]) async {
    Match match;
    
    if (teamAOrTeamA is Team && teamBOrTeamB is Team) {
      // Original method with Team objects
      match = Match.create(
        teamA: teamAOrTeamA,
        teamB: teamBOrTeamB,
      );
    } else if (teamAOrTeamA is String && teamBOrTeamB is String) {
      // New method with string IDs and config
      match = Match(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teamAId: teamAOrTeamA,
        teamBId: teamBOrTeamB,
        teamAScore: 0,
        teamBScore: 0,
        startTime: DateTime.now(),
        isComplete: false,
      );
    } else {
      throw ArgumentError('Invalid arguments for createMatch');
    }

    await _matchesBox.put(match.id, match);
    _matches = {..._matches, match.id: match};
    notifyListeners();
    return match;
  }

  // Create a new match with named parameters
  Future<Match> createMatchWithTeams({
    required Team teamA,
    required Team teamB,
  }) async {
    return createMatch(teamA, teamB);
  }

  // Update an existing match
  Future<void> updateMatch(Match match) async {
    await _matchesBox.put(match.id, match);
    _matches = {..._matches, match.id: match};
    notifyListeners();
  }

  // Delete a match
  Future<void> deleteMatch(String id) async {
    await _matchesBox.delete(id);
    final matches = {..._matches};
    matches.remove(id);
    _matches = matches;
    notifyListeners();
  }

  // Get a match by ID
  Match? getMatch(String id) {
    return _matches[id];
  }

  // Get all matches as a list
  List<Match> getAllMatches() {
    return _matches.values.toList();
  }

  // Increment score for team A
  Future<void> incrementTeamAScore(String matchId) async {
    final match = _matches[matchId];
    if (match != null) {
      match.incrementTeamAScore();
      await updateMatch(match);
    }
  }

  // Increment score for team B
  Future<void> incrementTeamBScore(String matchId) async {
    final match = _matches[matchId];
    if (match != null) {
      match.incrementTeamBScore();
      await updateMatch(match);
    }
  }

  // Decrement score for team A
  Future<void> decrementTeamAScore(String matchId) async {
    final match = _matches[matchId];
    if (match != null) {
      match.decrementTeamAScore();
      await updateMatch(match);
    }
  }

  // Decrement score for team B
  Future<void> decrementTeamBScore(String matchId) async {
    final match = _matches[matchId];
    if (match != null) {
      match.decrementTeamBScore();
      await updateMatch(match);
    }
  }

  // Complete a match
  Future<void> completeMatch(String matchId, [String? winner]) async {
    final match = _matches[matchId];
    if (match != null && !match.isComplete) {
      match.completeMatch();
      await updateMatch(match);
    }
  }

  // Get active match (most recent incomplete match)
  Match? getActiveMatch() {
    final activeMatches = _matches.values
        .where((match) => !match.isComplete)
        .where((match) => DateTime.now().difference(match.startTime).inHours < 6) // Partidas de até 6h
        .toList();
    
    if (activeMatches.isEmpty) return null;
    
    // Return the most recent active match
    activeMatches.sort((a, b) => b.startTime.compareTo(a.startTime));
    return activeMatches.first;
  }

  // Get all active matches
  List<Match> getActiveMatches() {
    return _matches.values
        .where((match) => !match.isComplete)
        .where((match) => DateTime.now().difference(match.startTime).inHours < 6)
        .toList();
  }

  // Check if there are any active matches
  bool hasActiveMatch() {
    return getActiveMatch() != null;
  }

  // Reload matches from Hive (useful after import operations)
  Future<void> reloadMatches() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _matches = _loadMatches();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }
}
