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

  MatchesNotifier() {
    _init();
  }

  Map<String, Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    try {
      await _initHive();
      _matches = _loadMatches();
      _isLoading = false;
      _error = null;
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
  Future<Match> createMatch({
    required Team teamA,
    required Team teamB,
  }) async {
    final match = Match.create(
      teamA: teamA,
      teamB: teamB,
    );

    await _matchesBox.put(match.id, match);
    _matches = {..._matches, match.id: match};
    notifyListeners();
    return match;
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
  Future<void> completeMatch(String matchId) async {
    final match = _matches[matchId];
    if (match != null && !match.isComplete) {
      match.completeMatch();
      await updateMatch(match);
    }
  }
}
