import 'package:hive/hive.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';

part 'tournament.g.dart';

@HiveType(typeId: 6)
class Tournament {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final GameConfig config;

  @HiveField(3)
  List<String> teamIds; // IDs of teams in the tournament

  @HiveField(4)
  List<String> queueIds; // IDs of teams in the queue

  @HiveField(5)
  String? waitingTeamId; // ID of team in waiting mode

  @HiveField(6)
  String? challengerId; // Team that should challenge the waiting team

  @HiveField(7)
  List<String> matchIds; // IDs of matches played

  @HiveField(8)
  String? currentMatchId; // ID of current match

  @HiveField(11)
  DateTime createdAt;

  @HiveField(9)
  DateTime? completedAt;

  @HiveField(10)
  bool isComplete;

  Tournament({
    required this.id,
    required this.name,
    required this.config,
    required this.teamIds,
    required this.queueIds,
    this.waitingTeamId,
    this.challengerId,
    List<String>? matchIds,
    this.currentMatchId,
    required this.createdAt,
    this.completedAt,
    this.isComplete = false,
  }) : matchIds = matchIds ?? <String>[];

  // Factory constructor to create a new tournament
  factory Tournament.create({
    required String name,
    required GameConfig config,
    required List<Team> teams,
    bool shuffleTeams = true,
  }) {
    // Create queue of team IDs
    final teamIds = teams.map((team) => team.id).toList();
    final queueIds = List<String>.from(teamIds);

    if (shuffleTeams) {
      queueIds.shuffle(); // Randomize initial queue order
    }
    // If shuffleTeams is false, maintain the original selection order

    return Tournament(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      config: config,
      teamIds: teamIds,
      queueIds: queueIds,
      createdAt: DateTime.now(),
    );
  }

  // Get the next match teams
  List<String>? getNextMatchTeamIds() {
    // Check if we need a challenger vs waiting team match
    if (waitingTeamId != null && challengerId != null) {
      return [waitingTeamId!, challengerId!];
    }

    // Regular queue matches
    if (queueIds.length < 2) return null;
    return [queueIds[0], queueIds[1]];
  }

  // Start a new match
  void startMatch(Match match) {
    currentMatchId = match.id;
    matchIds.add(match.id);
  }

  // Process match result and update queue
  void processMatchResult(Match match, Map<String, Team> teamsMap) {
    if (!match.isComplete) return;

    // Get the teams involved
    final teamA = teamsMap[match.teamAId]!;
    final teamB = teamsMap[match.teamBId]!;

    // Check if this match involved a waiting team returning to play
    bool waitingTeamReturned = false;
    if (waitingTeamId != null &&
        (match.teamAId == waitingTeamId || match.teamBId == waitingTeamId)) {
      waitingTeamReturned = true;
      // Clear waiting status
      final waitingTeam = teamsMap[waitingTeamId]!;
      waitingTeam.isWaiting = false;
      waitingTeam
          .resetConsecutiveWins(); // Reset consecutive wins when returning
      waitingTeamId = null;
      challengerId = null; // Clear challenger as the match is complete
    }

    // Update team stats
    if (match.winnerId != null && match.loserId != null) {
      final winner = teamsMap[match.winnerId]!;
      final loser = teamsMap[match.loserId]!;

      winner.addWin();
      loser.addLoss();

      // Update queue - "King of the Hill" logic
      // Remove the loser from the queue (if they're in it)
      queueIds.remove(loser.id);

      // If the winner was the waiting team, they need to be added back to the queue
      if (waitingTeamReturned && winner.id == match.winnerId) {
        // Winner was the waiting team, add them to the front of the queue
        queueIds.insert(0, winner.id);
      } else if (!queueIds.contains(winner.id)) {
        // If winner is not in queue (shouldn't happen in normal flow), add to front
        queueIds.insert(0, winner.id);
      }

      // Check if winner should enter waiting mode (only if they weren't just returning and waiting mode is enabled)
      if (!waitingTeamReturned &&
          config.waitingModeEnabled &&
          winner.consecutiveWins >= config.winsForWaitingMode) {
        // Winner enters waiting mode, remove from queue
        queueIds.remove(winner.id);
        waitingTeamId = winner.id;
        winner.isWaiting = true;
        challengerId = null; // Clear any pending challenger
      } else if (waitingTeamId != null && !waitingTeamReturned) {
        // There's a waiting team and current winner should challenge them
        // Remove winner from queue and set as challenger
        queueIds.remove(winner.id);
        challengerId = winner.id;
      } else {
        // Clear challenger if no waiting team or winner was returning
        challengerId = null;
      }
      // If winner doesn't enter waiting mode and there's no waiting team,
      // they stay at the front of the queue to face the next challenger

      // Loser always goes to the back of the queue
      queueIds.add(loser.id);
    } else {
      // In case of a draw, both teams go to the back of the queue
      queueIds.remove(teamA.id);
      queueIds.remove(teamB.id);
      queueIds.add(teamA.id);
      queueIds.add(teamB.id);

      // If there was a waiting team involved in the draw, clear waiting status
      if (waitingTeamReturned) {
        // Both teams get added back to queue, no one stays waiting
      }

      // Clear challenger in case of draw
      challengerId = null;
    }

    // Clear current match
    currentMatchId = null;

    // Check if tournament is complete
    if (config.isTournamentComplete(matchIds.length)) {
      completeTournament();
    }
  }

  // Complete the tournament
  void completeTournament() {
    isComplete = true;
    completedAt = DateTime.now();
  }

  // Reset the tournament
  void reset(Map<String, Team> teamsMap) {
    // Reset all team stats
    for (final teamId in teamIds) {
      teamsMap[teamId]?.resetStats();
    }

    // Reset queue
    queueIds = List<String>.from(teamIds);
    queueIds.shuffle();

    // Reset other properties
    waitingTeamId = null;
    matchIds.clear();
    currentMatchId = null;
    isComplete = false;
    completedAt = null;
  }
}
