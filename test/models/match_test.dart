import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/match.dart';

void main() {
  group('Match Model Tests', () {
    late DateTime testStartTime;
    late DateTime testEndTime;

    setUp(() {
      testStartTime = DateTime(2024, 1, 1, 10, 0, 0);
      testEndTime = DateTime(2024, 1, 1, 11, 30, 0);
    });

    test('should create a match with required parameters', () {
      // Arrange
      const id = 'match-1';
      const teamAId = 'team-a';
      const teamBId = 'team-b';

      // Act
      final match = Match(
        id: id,
        teamAId: teamAId,
        teamBId: teamBId,
        startTime: testStartTime,
      );

      // Assert
      expect(match.id, equals(id));
      expect(match.teamAId, equals(teamAId));
      expect(match.teamBId, equals(teamBId));
      expect(match.teamAScore, equals(0));
      expect(match.teamBScore, equals(0));
      expect(match.startTime, equals(testStartTime));
      expect(match.endTime, isNull);
      expect(match.durationInSeconds, equals(0));
      expect(match.isComplete, isFalse);
      expect(match.winnerId, isNull);
      expect(match.loserId, isNull);
    });

    test('should create a match with all parameters', () {
      // Arrange
      const id = 'match-2';
      const teamAId = 'team-a';
      const teamBId = 'team-b';
      const teamAScore = 3;
      const teamBScore = 2;
      const durationInSeconds = 5400; // 90 minutes
      const isComplete = true;
      const winnerId = 'team-a';
      const loserId = 'team-b';

      // Act
      final match = Match(
        id: id,
        teamAId: teamAId,
        teamBId: teamBId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        startTime: testStartTime,
        endTime: testEndTime,
        durationInSeconds: durationInSeconds,
        isComplete: isComplete,
        winnerId: winnerId,
        loserId: loserId,
      );

      // Assert
      expect(match.id, equals(id));
      expect(match.teamAId, equals(teamAId));
      expect(match.teamBId, equals(teamBId));
      expect(match.teamAScore, equals(teamAScore));
      expect(match.teamBScore, equals(teamBScore));
      expect(match.startTime, equals(testStartTime));
      expect(match.endTime, equals(testEndTime));
      expect(match.durationInSeconds, equals(durationInSeconds));
      expect(match.isComplete, equals(isComplete));
      expect(match.winnerId, equals(winnerId));
      expect(match.loserId, equals(loserId));
    });

    test('should update team A score', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
      );

      // Act
      match.teamAScore = 5;

      // Assert
      expect(match.teamAScore, equals(5));
    });

    test('should update team B score', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
      );

      // Act
      match.teamBScore = 3;

      // Assert
      expect(match.teamBScore, equals(3));
    });

    test('should mark match as complete', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
      );

      // Act
      match.isComplete = true;
      match.endTime = testEndTime;

      // Assert
      expect(match.isComplete, isTrue);
      expect(match.endTime, equals(testEndTime));
    });

    test('should set winner and loser', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
        teamAScore: 4,
        teamBScore: 2,
      );

      // Act
      match.winnerId = 'team-a';
      match.loserId = 'team-b';

      // Assert
      expect(match.winnerId, equals('team-a'));
      expect(match.loserId, equals('team-b'));
    });

    test('should handle tie game (no winner or loser)', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
        teamAScore: 2,
        teamBScore: 2,
        isComplete: true,
      );

      // Assert
      expect(match.winnerId, isNull);
      expect(match.loserId, isNull);
      expect(match.teamAScore, equals(match.teamBScore));
    });

    test('should calculate duration correctly', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
        durationInSeconds: 3600, // 1 hour
      );

      // Assert
      expect(match.durationInSeconds, equals(3600));
    });

    test('should handle match without end time', () {
      // Arrange
      final match = Match(
        id: 'match-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        startTime: testStartTime,
      );

      // Assert
      expect(match.endTime, isNull);
      expect(match.isComplete, isFalse);
    });

    test('should validate team IDs are different', () {
      // Arrange
      const id = 'match-1';
      const teamAId = 'team-a';
      const teamBId = 'team-b';

      // Act
      final match = Match(
        id: id,
        teamAId: teamAId,
        teamBId: teamBId,
        startTime: testStartTime,
      );

      // Assert
      expect(match.teamAId, isNot(equals(match.teamBId)));
    });
  });
}
