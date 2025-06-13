import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'team.g.dart';

@HiveType(typeId: 1)
class Team {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> members;

  @HiveField(3)
  String? emoji;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  Color color;

  @HiveField(6)
  int wins;

  @HiveField(7)
  int losses;

  @HiveField(8)
  int consecutiveWins;

  @HiveField(9)
  bool isWaiting;

  @HiveField(10)
  Map<String, int> tournamentConsecutiveWins;

  Team({
    required this.id,
    required this.name,
    this.members = const [],
    this.emoji,
    this.imagePath,
    required this.color,
    this.wins = 0,
    this.losses = 0,
    this.consecutiveWins = 0,
    this.isWaiting = false,
    this.tournamentConsecutiveWins = const {},
  });

  // Factory constructor to create a team with default values
  factory Team.create({
    required String id,
    String? name,
    Color? color,
  }) {
    return Team(
      id: id,
      name: name ?? 'Equipe $id',
      color: color ?? Colors.blue,
    );
  }

  // Clone method to create a copy of the team
  Team copyWith({
    String? id,
    String? name,
    List<String>? members,
    String? emoji,
    String? imagePath,
    Color? color,
    int? wins,
    int? losses,
    int? consecutiveWins,
    bool? isWaiting,
    Map<String, int>? tournamentConsecutiveWins,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
      color: color ?? this.color,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      consecutiveWins: consecutiveWins ?? this.consecutiveWins,
      isWaiting: isWaiting ?? this.isWaiting,
      tournamentConsecutiveWins: tournamentConsecutiveWins ?? Map<String, int>.from(this.tournamentConsecutiveWins),
    );
  }

  // Reset team stats for a new tournament
  void resetStats() {
    wins = 0;
    losses = 0;
    consecutiveWins = 0;
    isWaiting = false;
  }

  // Add a win to the team's record
  void addWin([String? tournamentId]) {
    wins++;
    consecutiveWins++;
    if (tournamentId != null) {
      tournamentConsecutiveWins = Map<String, int>.from(tournamentConsecutiveWins);
      tournamentConsecutiveWins[tournamentId] = getTournamentConsecutiveWins(tournamentId) + 1;
    }
  }

  // Add a loss to the team's record
  void addLoss([String? tournamentId]) {
    losses++;
    consecutiveWins = 0;
    isWaiting = false;
    if (tournamentId != null) {
      tournamentConsecutiveWins = Map<String, int>.from(tournamentConsecutiveWins);
      tournamentConsecutiveWins[tournamentId] = 0;
    }
  }

  // Reset consecutive wins (used when returning from waiting mode)
  void resetConsecutiveWins([String? tournamentId]) {
    consecutiveWins = 0;
    if (tournamentId != null) {
      tournamentConsecutiveWins = Map<String, int>.from(tournamentConsecutiveWins);
      tournamentConsecutiveWins[tournamentId] = 0;
    }
  }

  // Get consecutive wins for a specific tournament
  int getTournamentConsecutiveWins(String tournamentId) {
    return tournamentConsecutiveWins[tournamentId] ?? 0;
  }

  // Reset consecutive wins for a specific tournament
  void resetTournamentConsecutiveWins(String tournamentId) {
    tournamentConsecutiveWins = Map<String, int>.from(tournamentConsecutiveWins);
    tournamentConsecutiveWins[tournamentId] = 0;
  }

  // Initialize tournament consecutive wins (called when starting a new tournament)
  void initializeTournamentStats(String tournamentId) {
    tournamentConsecutiveWins = Map<String, int>.from(tournamentConsecutiveWins);
    tournamentConsecutiveWins[tournamentId] = 0;
  }

  // Calculate win rate as a percentage
  double get winRate {
    final total = totalGames;
    return total > 0 ? (wins / total) * 100 : 0.0;
  }

  // Calculate total games played
  int get totalGames => wins + losses;
}
