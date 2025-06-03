import 'package:hive/hive.dart';
import 'package:placar_iterativo_app/models/team.dart';

part 'match.g.dart';

@HiveType(typeId: 5)
class Match {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teamAId;

  @HiveField(2)
  final String teamBId;

  @HiveField(3)
  int teamAScore;

  @HiveField(4)
  int teamBScore;

  @HiveField(5)
  DateTime startTime;

  @HiveField(6)
  DateTime? endTime;

  @HiveField(7)
  int durationInSeconds;

  @HiveField(8)
  bool isComplete;

  @HiveField(9)
  String? winnerId;

  @HiveField(10)
  String? loserId;

  Match({
    required this.id,
    required this.teamAId,
    required this.teamBId,
    this.teamAScore = 0,
    this.teamBScore = 0,
    required this.startTime,
    this.endTime,
    this.durationInSeconds = 0,
    this.isComplete = false,
    this.winnerId,
    this.loserId,
  });

  // Factory constructor to create a new match
  factory Match.create({
    required Team teamA,
    required Team teamB,
  }) {
    return Match(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamAId: teamA.id,
      teamBId: teamB.id,
      startTime: DateTime.now(),
    );
  }

  // Increment score for team A
  void incrementTeamAScore() {
    teamAScore++;
  }

  // Increment score for team B
  void incrementTeamBScore() {
    teamBScore++;
  }

  // Decrement score for team A (with validation to prevent negative scores)
  void decrementTeamAScore() {
    if (teamAScore > 0) {
      teamAScore--;
    }
  }

  // Decrement score for team B (with validation to prevent negative scores)
  void decrementTeamBScore() {
    if (teamBScore > 0) {
      teamBScore--;
    }
  }

  // Complete the match and determine the winner
  void completeMatch() {
    endTime = DateTime.now();
    durationInSeconds = endTime!.difference(startTime).inSeconds;
    isComplete = true;

    // Determine winner and loser
    if (teamAScore > teamBScore) {
      winnerId = teamAId;
      loserId = teamBId;
    } else if (teamBScore > teamAScore) {
      winnerId = teamBId;
      loserId = teamAId;
    }
    // If scores are equal, winnerId and loserId remain null (draw)
  }

  // Check if the match is a draw
  bool isDraw() {
    return isComplete && winnerId == null && loserId == null;
  }

  // Get the current duration of the match in seconds
  int getCurrentDuration() {
    if (isComplete && endTime != null) {
      return durationInSeconds;
    }
    return DateTime.now().difference(startTime).inSeconds;
  }
}