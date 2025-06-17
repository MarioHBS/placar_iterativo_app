import 'package:hive/hive.dart';

part 'game_config.g.dart';

@HiveType(typeId: 2)
enum GameMode {
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

@HiveType(typeId: 5)
enum TournamentEndCondition {
  @HiveField(0)
  none,
  @HiveField(1)
  firstToWins, // Primeiro a X vitórias
  @HiveField(2)
  mostWinsInRounds, // Maior número de vitórias em X rodadas
  @HiveField(3)
  pointsSystem, // Sistema de pontos acumulados
  @HiveField(4)
  totalDuration, // Duração total do torneio
  @HiveField(5)
  specificDeadline, // Deadline específico
  @HiveField(6)
  maxMatches, // Número máximo de partidas
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
  bool?
      _waitingModeEnabled; // whether waiting mode is enabled for this tournament

  @HiveField(8)
  TournamentEndCondition? tournamentEndCondition;

  @HiveField(9)
  int? firstToWinsCount; // X vitórias para finalizar torneio

  @HiveField(10)
  int? roundsCount; // X rodadas para maior número de vitórias

  @HiveField(11)
  int? targetPoints; // X pontos para sistema de pontos

  @HiveField(12)
  int? tournamentDurationMinutes; // duração total em minutos

  @HiveField(13)
  DateTime? specificDeadline; // deadline específico

  @HiveField(14)
  int? maxTournamentMatches; // número máximo de partidas do torneio

  GameConfig({
    required this.id,
    this.gameMode = GameMode.tournament,
    this.endCondition,
    this.timeLimit,
    this.scoreLimit,
    this.winsForWaitingMode = 3,
    this.totalMatches,
    bool waitingModeEnabled = true,
    this.tournamentEndCondition,
    this.firstToWinsCount,
    this.roundsCount,
    this.targetPoints,
    this.tournamentDurationMinutes,
    this.specificDeadline,
    this.maxTournamentMatches,
  }) : _waitingModeEnabled = waitingModeEnabled;

  // Getter for waitingModeEnabled with default value
  bool get waitingModeEnabled => _waitingModeEnabled ?? true;

  // Factory constructor for tournament mode
  factory GameConfig.tournamentMode({
    EndCondition endCondition = EndCondition.score,
    int? timeLimit,
    int? scoreLimit,
    int winsForWaitingMode = 3,
    int? totalMatches,
    bool waitingModeEnabled = true,
    TournamentEndCondition? tournamentEndCondition,
    int? firstToWinsCount,
    int? roundsCount,
    int? targetPoints,
    int? tournamentDurationMinutes,
    DateTime? specificDeadline,
    int? maxTournamentMatches,
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
      tournamentEndCondition: tournamentEndCondition,
      firstToWinsCount: firstToWinsCount,
      roundsCount: roundsCount,
      targetPoints: targetPoints,
      tournamentDurationMinutes: tournamentDurationMinutes,
      specificDeadline: specificDeadline,
      maxTournamentMatches: maxTournamentMatches,
    );
  }

  // Check if the game should end based on time
  bool shouldEndByTime(int elapsedSeconds) {
    if (endCondition == EndCondition.time ||
        endCondition == EndCondition.both) {
      return timeLimit != null && elapsedSeconds >= timeLimit!;
    }
    return false;
  }

  // Check if the game should end based on score
  bool shouldEndByScore(int teamAScore, int teamBScore) {
    if (endCondition == EndCondition.score ||
        endCondition == EndCondition.both) {
      return scoreLimit != null &&
          (teamAScore >= scoreLimit! || teamBScore >= scoreLimit!);
    }
    return false;
  }

  // Check if the tournament is complete
  bool isTournamentComplete(int matchesPlayed) {
    return totalMatches != null && matchesPlayed >= totalMatches!;
  }
}
