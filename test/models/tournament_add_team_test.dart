import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:flutter/material.dart';

void main() {
  group('Tournament Add Team Tests', () {
    late GameConfig gameConfig;
    late List<Team> initialTeams;
    late Tournament tournament;
    late Team newTeam;

    setUp(() {
      gameConfig = GameConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scoreLimit: 10,
        timeLimit: 900, // 15 * 60
      );

      initialTeams = [
        Team(
          id: 'team-1',
          name: 'Team A',
          emoji: '🔴',
          color: Colors.red,
        ),
        Team(
          id: 'team-2',
          name: 'Team B',
          emoji: '🔵',
          color: Colors.blue,
        ),
        Team(
          id: 'team-3',
          name: 'Team C',
          emoji: '🟢',
          color: Colors.green,
        ),
      ];

      newTeam = Team(
        id: 'team-4',
        name: 'Team D',
        emoji: '🟡',
        color: Colors.yellow,
      );

      tournament = Tournament.create(
        name: 'Test Tournament',
        config: gameConfig,
        teams: initialTeams,
        shuffleTeams: false,
      );
    });

    test('should add new team to tournament successfully', () {
      // Arrange
      final initialTeamCount = tournament.teamIds.length;
      final initialQueueCount = tournament.queueIds.length;

      // Act
      tournament.addTeamToTournament(newTeam);

      // Assert
      expect(tournament.teamIds.length, equals(initialTeamCount + 1));
      expect(tournament.queueIds.length, equals(initialQueueCount + 1));
      expect(tournament.teamIds.contains(newTeam.id), isTrue);
      expect(tournament.queueIds.contains(newTeam.id), isTrue);
      expect(tournament.queueIds.last, equals(newTeam.id)); // Should be added to the end
    });

    test('should not add duplicate team to tournament', () {
      // Arrange
      final existingTeam = initialTeams.first;
      final initialTeamCount = tournament.teamIds.length;
      final initialQueueCount = tournament.queueIds.length;

      // Act
      tournament.addTeamToTournament(existingTeam);

      // Assert
      expect(tournament.teamIds.length, equals(initialTeamCount));
      expect(tournament.queueIds.length, equals(initialQueueCount));
    });

    test('should initialize tournament stats for new team', () {
      // Act
      tournament.addTeamToTournament(newTeam);

      // Assert
      expect(newTeam.getTournamentConsecutiveWins(tournament.id), equals(0));
      expect(newTeam.tournamentConsecutiveWins.containsKey(tournament.id), isTrue);
    });

    test('should remove team from tournament successfully', () {
      // Arrange
      final teamToRemove = initialTeams.first;
      final initialTeamCount = tournament.teamIds.length;
      final initialQueueCount = tournament.queueIds.length;

      // Act
      tournament.removeTeamFromTournament(teamToRemove.id);

      // Assert
      expect(tournament.teamIds.length, equals(initialTeamCount - 1));
      expect(tournament.queueIds.length, equals(initialQueueCount - 1));
      expect(tournament.teamIds.contains(teamToRemove.id), isFalse);
      expect(tournament.queueIds.contains(teamToRemove.id), isFalse);
    });

    test('should clear waiting status when removing waiting team', () {
      // Arrange
      final waitingTeam = initialTeams.first;
      tournament.waitingTeamId = waitingTeam.id;
      waitingTeam.isWaiting = true;

      // Act
      tournament.removeTeamFromTournament(waitingTeam.id);

      // Assert
      expect(tournament.waitingTeamId, isNull);
    });

    test('should clear challenger status when removing challenger team', () {
      // Arrange
      final challengerTeam = initialTeams.first;
      tournament.challengerId = challengerTeam.id;

      // Act
      tournament.removeTeamFromTournament(challengerTeam.id);

      // Assert
      expect(tournament.challengerId, isNull);
    });

    test('should handle adding team to queue correctly', () {
      // Arrange
      final originalQueue = List<String>.from(tournament.queueIds);

      // Act
      tournament.addTeamToTournament(newTeam);

      // Assert
      expect(tournament.queueIds.take(originalQueue.length).toList(), equals(originalQueue));
      expect(tournament.queueIds.last, equals(newTeam.id));
    });

    test('should maintain tournament integrity after adding team', () {
      // Arrange
      final originalTeamIds = Set<String>.from(tournament.teamIds);
      final originalQueueIds = List<String>.from(tournament.queueIds);

      // Act
      tournament.addTeamToTournament(newTeam);

      // Assert
      // All original teams should still be present
      for (final teamId in originalTeamIds) {
        expect(tournament.teamIds.contains(teamId), isTrue);
      }
      
      // Queue should maintain original order with new team at the end
      for (int i = 0; i < originalQueueIds.length; i++) {
        expect(tournament.queueIds[i], equals(originalQueueIds[i]));
      }
      
      // New team should be at the end of queue
      expect(tournament.queueIds.last, equals(newTeam.id));
    });
  });
}