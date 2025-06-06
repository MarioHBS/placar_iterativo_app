import 'package:hive/hive.dart';

part 'game_config.g.dart';

@HiveType(typeId: 2)
enum GameMode {
  @HiveField(0)
  free,
  @HiveField(1)
  tournament
}

@HiveType(typeId: 3)
enum EndCondition {
  @HiveField(0)
  none,
  @HiveField(1)
  time,
  @HiveField(2)
  score,
  @HiveField(3)
  both
}

@HiveType(typeId: 4)
class GameConfig {
  @HiveField(0)
  final String id;

  @HiveField(1)
  GameMode gameMode;

  @HiveField(2)
  EndCondition? endCondition;

  @HiveField(3)
  int? timeLimit; // in seconds

  @HiveField(4)
  int? scoreLimit;

  @HiveField(5)
  int winsForWaitingMode; // number of consecutive wins to enter waiting mode

  @HiveField(6)
  int?
      totalMatches; // total number of matches in tournament, null for unlimited

  @HiveField(7)
  bool
      waitingModeEnabled; // whether waiting mode is enabled for this tournament

  GameConfig({
    required this.id,
    required this.gameMode,
    this.endCondition,
    this.timeLimit,
    this.scoreLimit,
    this.winsForWaitingMode = 3,
    this.totalMatches,
    this.waitingModeEnabled = true,
  });

  // Factory constructor for free mode
  factory GameConfig.freeMode() {
    return GameConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameMode: GameMode.free,
      winsForWaitingMode: 3,
    );
  }

  // Factory constructor for tournament mode
  factory GameConfig.tournamentMode({
    EndCondition endCondition = EndCondition.score,
    int? timeLimit,
    int? scoreLimit,
    int winsForWaitingMode = 3,
    int? totalMatches,
    bool waitingModeEnabled = true,
  }) {
    return GameConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameMode: GameMode.tournament,
      endCondition: endCondition,
      timeLimit: timeLimit,
      scoreLimit: scoreLimit,
      winsForWaitingMode: winsForWaitingMode,
      totalMatches: totalMatches,
      waitingModeEnabled: waitingModeEnabled,
    );
  }

  // Check if the game should end based on time
  bool shouldEndByTime(int elapsedSeconds) {
    if (gameMode == GameMode.free) return false;
    if (endCondition == EndCondition.time ||
        endCondition == EndCondition.both) {
      return timeLimit != null && elapsedSeconds >= timeLimit!;
    }
    return false;
  }

  // Check if the game should end based on score
  bool shouldEndByScore(int teamAScore, int teamBScore) {
    if (gameMode == GameMode.free) return false;
    if (endCondition == EndCondition.score ||
        endCondition == EndCondition.both) {
      return scoreLimit != null &&
          (teamAScore >= scoreLimit! || teamBScore >= scoreLimit!);
    }
    return false;
  }

  // Check if the tournament is complete
  bool isTournamentComplete(int matchesPlayed) {
    if (gameMode == GameMode.free) return false;
    return totalMatches != null && matchesPlayed >= totalMatches!;
  }
}
