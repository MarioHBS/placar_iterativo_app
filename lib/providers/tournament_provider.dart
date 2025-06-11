import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';

class TournamentNotifier extends ChangeNotifier {
  static const String _boxName = 'tournaments';
  late Box<Tournament> _tournamentsBox;
  Map<String, Tournament> _tournaments = {};
  bool _isLoading = true;
  String? _error;

  TournamentNotifier() {
    _init();
  }

  Map<String, Tournament> get tournaments => _tournaments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    try {
      await _initHive();
      _tournaments = _loadTournaments();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> _initHive() async {
    _tournamentsBox = await Hive.openBox<Tournament>(_boxName);
  }

  Map<String, Tournament> _loadTournaments() {
    final tournaments = <String, Tournament>{};
    for (final key in _tournamentsBox.keys) {
      final tournament = _tournamentsBox.get(key);
      if (tournament != null) {
        tournaments[key.toString()] = tournament;
      }
    }
    return tournaments;
  }

  // Create a new tournament
  Future<Tournament> createTournament({
    required String name,
    required GameConfig config,
    required List<Team> teams,
    bool shuffleTeams = true,
  }) async {
    final tournament = Tournament.create(
      name: name,
      config: config,
      teams: teams,
      shuffleTeams: shuffleTeams,
    );

    await _tournamentsBox.put(tournament.id, tournament);
    _tournaments = {..._tournaments, tournament.id: tournament};
    notifyListeners();
    return tournament;
  }

  // Update an existing tournament
  Future<void> updateTournament(Tournament tournament) async {
    await _tournamentsBox.put(tournament.id, tournament);
    _tournaments = {..._tournaments, tournament.id: tournament};
    notifyListeners();
  }

  // Delete a tournament
  Future<void> deleteTournament(String id) async {
    await _tournamentsBox.delete(id);
    final tournaments = {..._tournaments};
    tournaments.remove(id);
    _tournaments = tournaments;
    notifyListeners();
  }

  // Get a tournament by ID
  Tournament? getTournament(String id) {
    return _tournaments[id];
  }

  // Get all tournaments as a list
  List<Tournament> getAllTournaments() {
    return _tournaments.values.toList();
  }

  // Start a new match in the tournament
  Future<Match?> startNextMatch(
    String tournamentId,
    TeamsNotifier teamsNotifier,
    MatchesNotifier matchesNotifier,
  ) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return null;

    // Get the next match team IDs
    final teamIds = tournament.getNextMatchTeamIds();
    if (teamIds == null || teamIds.length != 2) return null;

    // Get the teams
    final teamA = teamsNotifier.getTeam(teamIds[0]);
    final teamB = teamsNotifier.getTeam(teamIds[1]);
    if (teamA == null || teamB == null) return null;

    // Create the match
    final match = await matchesNotifier.createMatch(
      teamA: teamA,
      teamB: teamB,
    );

    // Update the tournament
    tournament.startMatch(match);
    await updateTournament(tournament);

    return match;
  }

  // Process a completed match
  Future<void> processMatchResult(
    String tournamentId,
    String matchId,
    TeamsNotifier teamsNotifier,
    MatchesNotifier matchesNotifier,
  ) async {
    final tournament = _tournaments[tournamentId];
    final match = matchesNotifier.getMatch(matchId);
    if (tournament == null || match == null || !match.isComplete) return;

    // Get all teams as a map
    final teamsMap = Map<String, Team>.fromEntries(
      teamsNotifier.getAllTeams().map((team) => MapEntry(team.id, team)),
    );

    // Process the match result
    tournament.processMatchResult(match, teamsMap);

    // Update the tournament
    await updateTournament(tournament);

    // Update the teams
    for (final team in teamsMap.values) {
      await teamsNotifier.updateTeam(team);
    }
  }

  // Reset a tournament
  Future<void> resetTournament(
    String tournamentId,
    TeamsNotifier teamsNotifier,
  ) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return;

    // Get all teams as a map
    final teamsMap = Map<String, Team>.fromEntries(
      teamsNotifier.getAllTeams().map((team) => MapEntry(team.id, team)),
    );

    // Reset the tournament
    tournament.reset(teamsMap);

    // Update the tournament
    await updateTournament(tournament);

    // Update the teams
    for (final team in teamsMap.values) {
      await teamsNotifier.updateTeam(team);
    }
  }

  // Reload tournaments from Hive (useful after import operations)
  Future<void> reloadTournaments() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _tournaments = _loadTournaments();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }
}
