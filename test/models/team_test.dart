import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/team.dart';

void main() {
  group('Team Model Tests', () {
    test('should create a team with required parameters', () {
      // Arrange
      const id = 'team-1';
      const name = 'Team A';
      const color = Colors.blue;

      // Act
      final team = Team(
        id: id,
        name: name,
        color: color,
      );

      // Assert
      expect(team.id, equals(id));
      expect(team.name, equals(name));
      expect(team.color, equals(color));
      expect(team.members, isEmpty);
      expect(team.wins, equals(0));
      expect(team.losses, equals(0));
      expect(team.consecutiveWins, equals(0));
      expect(team.isWaiting, isFalse);
    });

    test('should create a team with all parameters', () {
      // Arrange
      const id = 'team-2';
      const name = 'Team B';
      const members = ['Player 1', 'Player 2'];
      const emoji = '⚽';
      const imagePath = '/path/to/image.png';
      const color = Colors.red;
      const wins = 5;
      const losses = 2;
      const consecutiveWins = 3;
      const isWaiting = true;

      // Act
      final team = Team(
        id: id,
        name: name,
        members: members,
        emoji: emoji,
        imagePath: imagePath,
        color: color,
        wins: wins,
        losses: losses,
        consecutiveWins: consecutiveWins,
        isWaiting: isWaiting,
      );

      // Assert
      expect(team.id, equals(id));
      expect(team.name, equals(name));
      expect(team.members, equals(members));
      expect(team.emoji, equals(emoji));
      expect(team.imagePath, equals(imagePath));
      expect(team.color, equals(color));
      expect(team.wins, equals(wins));
      expect(team.losses, equals(losses));
      expect(team.consecutiveWins, equals(consecutiveWins));
      expect(team.isWaiting, equals(isWaiting));
    });

    test('should calculate win rate correctly', () {
      // Arrange
      final team = Team(
        id: 'team-1',
        name: 'Team A',
        color: Colors.blue,
        wins: 7,
        losses: 3,
      );

      // Act
      final winRate = team.winRate;

      // Assert
      expect(winRate, equals(70.0));
    });

    test('should return 0 win rate when no games played', () {
      // Arrange
      final team = Team(
        id: 'team-1',
        name: 'Team A',
        color: Colors.blue,
      );

      // Act
      final winRate = team.winRate;

      // Assert
      expect(winRate, equals(0.0));
    });

    test('should calculate total games correctly', () {
      // Arrange
      final team = Team(
        id: 'team-1',
        name: 'Team A',
        color: Colors.blue,
        wins: 5,
        losses: 3,
      );

      // Act
      final totalGames = team.totalGames;

      // Assert
      expect(totalGames, equals(8));
    });

    test('should update team name', () {
      // Arrange
      final team = Team(
        id: 'team-1',
        name: 'Old Name',
        color: Colors.blue,
      );
      const newName = 'New Name';

      // Act
      team.name = newName;

      // Assert
      expect(team.name, equals(newName));
    });

    test('should add member to team', () {
      // Arrange
      final team = Team(
        id: 'team-1',
        name: 'Team A',
        color: Colors.blue,
        members: ['Player 1'],
      );
      const newMember = 'Player 2';

      // Act
      team.members.add(newMember);

      // Assert
      expect(team.members, contains(newMember));
      expect(team.members.length, equals(2));
    });

    test('should create team with emoji', () {
      // Arrange & Act
      final team = Team(
        id: 'team-1',
        name: 'Team A',
        color: Colors.blue,
        emoji: '🏆',
      );

      // Assert
      expect(team.emoji, equals('🏆'));
    });

    test('should handle null emoji', () {
      // Arrange & Act
      final team = Team(
        id: 'team-1',
        name: 'Team A',
        color: Colors.blue,
      );

      // Assert
      expect(team.emoji, isNull);
    });
  });
}
