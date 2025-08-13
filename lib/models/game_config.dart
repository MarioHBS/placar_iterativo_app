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
    int? timeLimit,
    int? scoreLimit,
    this.winsForWaitingMode = 3,
    this.totalMatches,
    bool? waitingModeEnabled,
    this.tournamentEndCondition,
    int? firstToWinsCount,
    this.roundsCount,
    this.targetPoints,
    int? tournamentDurationMinutes,
    this.specificDeadline,
    this.maxTournamentMatches,
    // Compatibility parameters
    int? maxScore,
    Duration? maxTime,
    int? firstToWins,
    Duration? tournamentDuration,
  }) : _waitingModeEnabled = waitingModeEnabled,
       timeLimit = timeLimit ?? maxTime?.inSeconds,
       scoreLimit = scoreLimit ?? maxScore,
       firstToWinsCount = firstToWinsCount ?? firstToWins,
       tournamentDurationMinutes = tournamentDurationMinutes ?? tournamentDuration?.inMinutes;

  // Getter for waitingModeEnabled with default value
  bool get waitingModeEnabled => _waitingModeEnabled ?? true;

  // Getters for compatibility with tests
  int? get maxScore => scoreLimit;
  Duration? get maxTime => timeLimit != null ? Duration(seconds: timeLimit!) : null;
  int? get firstToWins => firstToWinsCount;
  Duration? get tournamentDuration => tournamentDurationMinutes != null ? Duration(minutes: tournamentDurationMinutes!) : null;

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
      if (scoreLimit == null) {
        return false;
      }

      final teamAHasReachedLimit = teamAScore >= scoreLimit!;
      final teamBHasReachedLimit = teamBScore >= scoreLimit!;

      if (!teamAHasReachedLimit && !teamBHasReachedLimit) {
        return false;
      }

      final scoreDifference = (teamAScore - teamBScore).abs();

      return scoreDifference >= 2;
    }
    return false;
  }

  // Validation methods
  bool isValidConfig() {
    if (endCondition == EndCondition.score && scoreLimit == null) {
      return false;
    }
    if (endCondition == EndCondition.time && timeLimit == null) {
      return false;
    }
    if (endCondition == EndCondition.both && (scoreLimit == null || timeLimit == null)) {
      return false;
    }
    return true;
  }

  bool hasTimeLimit() {
    return timeLimit != null;
  }

  bool hasScoreLimit() {
    return scoreLimit != null;
  }

  // Game completion check with multiple parameters
  bool isGameComplete({
    int? teamAScore,
    int? teamBScore,
    Duration? duration,
  }) {
    if (endCondition == EndCondition.none) {
      return false;
    }

    bool scoreConditionMet = false;
    bool timeConditionMet = false;

    // Check score condition
    if ((endCondition == EndCondition.score || endCondition == EndCondition.both) &&
        teamAScore != null && teamBScore != null && scoreLimit != null) {
      scoreConditionMet = teamAScore >= scoreLimit! || teamBScore >= scoreLimit!;
    }

    // Check time condition
    if ((endCondition == EndCondition.time || endCondition == EndCondition.both) &&
        duration != null && timeLimit != null) {
      timeConditionMet = duration.inSeconds >= timeLimit!;
    }

    // Return based on end condition
    switch (endCondition) {
      case EndCondition.score:
        return scoreConditionMet;
      case EndCondition.time:
        return timeConditionMet;
      case EndCondition.both:
        return scoreConditionMet || timeConditionMet;
      case EndCondition.none:
      default:
        return false;
    }
  }

  // Tournament completion check with multiple parameters
  bool isTournamentComplete({
    int? matchesPlayed,
    int? maxWins,
    Duration? tournamentDuration,
  }) {
    if (tournamentEndCondition == null || tournamentEndCondition == TournamentEndCondition.none) {
      return false;
    }

    switch (tournamentEndCondition!) {
      case TournamentEndCondition.firstToWins:
        return maxWins != null && firstToWinsCount != null && maxWins >= firstToWinsCount!;
      case TournamentEndCondition.maxMatches:
        return matchesPlayed != null && totalMatches != null && matchesPlayed >= totalMatches!;
      case TournamentEndCondition.totalDuration:
        return tournamentDuration != null && this.tournamentDuration != null && 
               tournamentDuration >= this.tournamentDuration!;
      default:
        return false;
    }
  }

  // Copy with method
  GameConfig copyWith({
    String? id,
    GameMode? gameMode,
    EndCondition? endCondition,
    int? timeLimit,
    int? scoreLimit,
    int? winsForWaitingMode,
    int? totalMatches,
    bool? waitingModeEnabled,
    TournamentEndCondition? tournamentEndCondition,
    int? firstToWinsCount,
    int? roundsCount,
    int? targetPoints,
    int? tournamentDurationMinutes,
    DateTime? specificDeadline,
    int? maxTournamentMatches,
    // Compatibility parameters
    int? maxScore,
    Duration? maxTime,
    int? firstToWins,
    Duration? tournamentDuration,
  }) {
    return GameConfig(
      id: id ?? this.id,
      gameMode: gameMode ?? this.gameMode,
      endCondition: endCondition ?? this.endCondition,
      timeLimit: timeLimit ?? (maxTime?.inSeconds) ?? this.timeLimit,
      scoreLimit: scoreLimit ?? maxScore ?? this.scoreLimit,
      winsForWaitingMode: winsForWaitingMode ?? this.winsForWaitingMode,
      totalMatches: totalMatches ?? this.totalMatches,
      waitingModeEnabled: waitingModeEnabled ?? this.waitingModeEnabled,
      tournamentEndCondition: tournamentEndCondition ?? this.tournamentEndCondition,
      firstToWinsCount: firstToWinsCount ?? firstToWins ?? this.firstToWinsCount,
      roundsCount: roundsCount ?? this.roundsCount,
      targetPoints: targetPoints ?? this.targetPoints,
      tournamentDurationMinutes: tournamentDurationMinutes ?? tournamentDuration?.inMinutes ?? this.tournamentDurationMinutes,
      specificDeadline: specificDeadline ?? this.specificDeadline,
      maxTournamentMatches: maxTournamentMatches ?? this.maxTournamentMatches,
    );
  }

  // Formatting methods
  String getEndConditionDescription() {
    switch (endCondition) {
      case EndCondition.score:
        return 'Primeiro a ${scoreLimit ?? 0} pontos';
      case EndCondition.time:
        return 'Tempo limite: ${getFormattedMaxTime()}';
      case EndCondition.both:
        return 'Primeiro a ${scoreLimit ?? 0} pontos ou ${getFormattedMaxTime()}';
      case EndCondition.none:
      default:
        return 'Sem condição de fim';
    }
  }

  String getFormattedMaxTime() {
    if (timeLimit == null) return '';
    
    final duration = Duration(seconds: timeLimit!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
