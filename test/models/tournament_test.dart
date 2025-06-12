import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/team.dart';

void main() {
  group('Tournament Model Tests', () {
    late GameConfig gameConfig;
    late List<Team> teams;
    late List<String> teamIds;

    setUp(() {
      gameConfig = GameConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scoreLimit: 10,
        timeLimit: 900, // 15 minutes in seconds
      );

      teams = [
        Team(
          id: 'team-1',
          name: 'Team A',
          color: Colors.blue,
        ),
        Team(
          id: 'team-2',
          name: 'Team B',
          color: Colors.red,
        ),
        Team(
          id: 'team-3',
          name: 'Team C',
          color: Colors.green,
        ),
      ];

      teamIds = teams.map((team) => team.id).toList();
    });

    test('should create a tournament with required parameters', () {
      // Arrange
      const id = 'tournament-1';
      const name = 'Test Tournament';

      // Act
      final tournament = Tournament(
        id: id,
        name: name,
        config: gameConfig,
        teamIds: teamIds,
        queueIds: [],
      );

      // Assert
      expect(tournament.id, equals(id));
      expect(tournament.name, equals(name));
      expect(tournament.config, equals(gameConfig));
      expect(tournament.teamIds, equals(teamIds));
      expect(tournament.queueIds, isEmpty);
      expect(tournament.waitingTeamId, isNull);
      expect(tournament.challengerId, isNull);
      expect(tournament.matchIds, isEmpty);
      expect(tournament.currentMatchId, isNull);
      expect(tournament.isComplete, isFalse);
      expect(tournament.completedAt, isNull);
      expect(tournament.createdAt, isNotNull);
    });

    test('should create a tournament with all parameters', () {
      // Arrange
      const id = 'tournament-2';
      const name = 'Complete Tournament';
      final queueIds = ['team-2', 'team-3'];
      const waitingTeamId = 'team-1';
      const challengerId = 'team-2';
      final matchIds = ['match-1', 'match-2'];
      const currentMatchId = 'match-1';
      final completedAt = DateTime.now();
      const isComplete = true;

      // Act
      final tournament = Tournament(
        id: id,
        name: name,
        config: gameConfig,
        teamIds: teamIds,
        queueIds: queueIds,
        waitingTeamId: waitingTeamId,
        challengerId: challengerId,
        matchIds: matchIds,
        currentMatchId: currentMatchId,
        completedAt: completedAt,
        isComplete: isComplete,
      );

      // Assert
      expect(tournament.id, equals(id));
      expect(tournament.name, equals(name));
      expect(tournament.config, equals(gameConfig));
      expect(tournament.teamIds, equals(teamIds));
      expect(tournament.queueIds, equals(queueIds));
      expect(tournament.waitingTeamId, equals(waitingTeamId));
      expect(tournament.challengerId, equals(challengerId));
      expect(tournament.matchIds, equals(matchIds));
      expect(tournament.currentMatchId, equals(currentMatchId));
      expect(tournament.completedAt, equals(completedAt));
      expect(tournament.isComplete, equals(isComplete));
    });

    test('should create tournament using factory constructor', () {
      // Arrange
      const name = 'Factory Tournament';
      const shuffleTeams = true;

      // Act
      final tournament = Tournament.create(
        name: name,
        config: gameConfig,
        teams: teams,
        shuffleTeams: shuffleTeams,
      );

      // Assert
      expect(tournament.name, equals(name));
      expect(tournament.config, equals(gameConfig));
      expect(tournament.teamIds.length, equals(teams.length));
      expect(tournament.id, isNotEmpty);
      expect(tournament.createdAt, isNotNull);
      expect(tournament.isComplete, isFalse);
    });

    test('should initialize tournament stats for teams when created', () {
      // Arrange
      const name = 'Stats Tournament';

      // Act
      final tournament = Tournament.create(
        name: name,
        config: gameConfig,
        teams: teams,
      );

      // Assert
      for (final team in teams) {
        expect(team.getTournamentConsecutiveWins(tournament.id), equals(0));
      }
    });

    test('should reset tournament correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Reset Tournament',
        config: gameConfig,
        teams: teams,
      );

      // Simulate some tournament state
      tournament.queueIds.addAll(['team-2', 'team-3']);
      tournament.waitingTeamId = 'team-1';
      tournament.challengerId = 'team-2';
      tournament.matchIds.add('match-1');
      tournament.currentMatchId = 'match-1';

      // Act
      tournament.reset({for (var team in teams) team.id: team});

      // Assert
      expect(tournament.queueIds, isEmpty);
      expect(tournament.waitingTeamId, isNull);
      expect(tournament.challengerId, isNull);
      expect(tournament.matchIds, isEmpty);
      expect(tournament.currentMatchId, isNull);
      expect(tournament.isComplete, isFalse);
      expect(tournament.completedAt, isNull);

      // Verify tournament stats are reset for all teams
      for (final team in teams) {
        expect(team.getTournamentConsecutiveWins(tournament.id), equals(0));
      }
    });

    test('should handle queue operations correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Queue Tournament',
        config: gameConfig,
        teams: teams,
      );

      // Act & Assert - Add to queue
      tournament.queueIds.add('team-1');
      expect(tournament.queueIds.contains('team-1'), isTrue);

      // Remove from queue
      tournament.queueIds.remove('team-1');
      expect(tournament.queueIds.contains('team-1'), isFalse);
    });

    test('should handle waiting team correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Waiting Tournament',
        config: gameConfig,
        teams: teams,
      );

      // Act
      tournament.waitingTeamId = 'team-1';

      // Assert
      expect(tournament.waitingTeamId, equals('team-1'));

      // Clear waiting team
      tournament.waitingTeamId = null;
      expect(tournament.waitingTeamId, isNull);
    });

    test('should handle challenger correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Challenger Tournament',
        config: gameConfig,
        teams: teams,
      );

      // Act
      tournament.challengerId = 'team-2';

      // Assert
      expect(tournament.challengerId, equals('team-2'));

      // Clear challenger
      tournament.challengerId = null;
      expect(tournament.challengerId, isNull);
    });

    test('should handle match tracking correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Match Tournament',
        config: gameConfig,
        teams: teams,
      );

      // Act
      tournament.matchIds.add('match-1');
      tournament.currentMatchId = 'match-1';

      // Assert
      expect(tournament.matchIds.contains('match-1'), isTrue);
      expect(tournament.currentMatchId, equals('match-1'));

      // Add another match
      tournament.matchIds.add('match-2');
      tournament.currentMatchId = 'match-2';
      expect(tournament.matchIds.length, equals(2));
      expect(tournament.currentMatchId, equals('match-2'));
    });

    test('should handle tournament completion correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Complete Tournament',
        config: gameConfig,
        teams: teams,
      );

      expect(tournament.isComplete, isFalse);
      expect(tournament.completedAt, isNull);

      // Act
      final completionTime = DateTime.now();
      tournament.isComplete = true;
      tournament.completedAt = completionTime;

      // Assert
      expect(tournament.isComplete, isTrue);
      expect(tournament.completedAt, equals(completionTime));
    });

    test('should update tournament name correctly', () {
      // Arrange
      final tournament = Tournament.create(
        name: 'Original Name',
        config: gameConfig,
        teams: teams,
      );

      // Act
      tournament.name = 'Updated Name';

      // Assert
      expect(tournament.name, equals('Updated Name'));
    });

    test('should maintain team order when not shuffled', () {
      // Arrange
      const name = 'Ordered Tournament';
      const shuffleTeams = false;

      // Act
      final tournament = Tournament.create(
        name: name,
        config: gameConfig,
        teams: teams,
        shuffleTeams: shuffleTeams,
      );

      // Assert
      expect(tournament.teamIds, equals(teamIds));
    });
  });
}