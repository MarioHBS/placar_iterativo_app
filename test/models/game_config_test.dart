import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/game_config.dart';

void main() {
  group('GameConfig Model Tests', () {
    test('should create a game config with required parameters', () {
      // Arrange
      const id = 'config-1';
      const gameMode = GameMode.tournament;

      // Act
      final config = GameConfig(
        id: id,
        gameMode: gameMode,
      );

      // Assert
      expect(config.id, equals(id));
      expect(config.gameMode, equals(gameMode));
      expect(config.endCondition, isNull);
      expect(config.timeLimit, isNull);
      expect(config.scoreLimit, isNull);
      expect(config.winsForWaitingMode, equals(3));
      expect(config.totalMatches, isNull);
    });

    test('should create a tournament game config with all parameters', () {
      // Arrange
      const id = 'config-2';
      const gameMode = GameMode.tournament;
      const endCondition = EndCondition.both;
      const timeLimit = 1800; // 30 minutes
      const scoreLimit = 10;
      const winsForWaitingMode = 5;
      const totalMatches = 20;

      // Act
      final config = GameConfig(
        id: id,
        gameMode: gameMode,
        endCondition: endCondition,
        timeLimit: timeLimit,
        scoreLimit: scoreLimit,
        winsForWaitingMode: winsForWaitingMode,
        totalMatches: totalMatches,
      );

      // Assert
      expect(config.id, equals(id));
      expect(config.gameMode, equals(gameMode));
      expect(config.endCondition, equals(endCondition));
      expect(config.timeLimit, equals(timeLimit));
      expect(config.scoreLimit, equals(scoreLimit));
      expect(config.winsForWaitingMode, equals(winsForWaitingMode));
      expect(config.totalMatches, equals(totalMatches));
    });

    test('should update game mode', () {
      // Arrange
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
      );

      // Act
      config.gameMode = GameMode.tournament;

      // Assert
      expect(config.gameMode, equals(GameMode.tournament));
    });

    test('should update end condition', () {
      // Arrange
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
      );

      // Act
      config.endCondition = EndCondition.time;

      // Assert
      expect(config.endCondition, equals(EndCondition.time));
    });

    test('should update time limit', () {
      // Arrange
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
      );
      const newTimeLimit = 3600; // 1 hour

      // Act
      config.timeLimit = newTimeLimit;

      // Assert
      expect(config.timeLimit, equals(newTimeLimit));
    });

    test('should update score limit', () {
      // Arrange
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
      );
      const newScoreLimit = 15;

      // Act
      config.scoreLimit = newScoreLimit;

      // Assert
      expect(config.scoreLimit, equals(newScoreLimit));
    });

    test('should update wins for waiting mode', () {
      // Arrange
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
      );
      const newWinsForWaitingMode = 7;

      // Act
      config.winsForWaitingMode = newWinsForWaitingMode;

      // Assert
      expect(config.winsForWaitingMode, equals(newWinsForWaitingMode));
    });

    test('should update total matches', () {
      // Arrange
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
      );
      const newTotalMatches = 50;

      // Act
      config.totalMatches = newTotalMatches;

      // Assert
      expect(config.totalMatches, equals(newTotalMatches));
    });

    test('should handle null values correctly', () {
      // Arrange & Act
      final config = GameConfig(
        id: 'config-1',
        gameMode: GameMode.tournament,
        endCondition: null,
        timeLimit: null,
        scoreLimit: null,
        totalMatches: null,
      );

      // Assert
      expect(config.endCondition, isNull);
      expect(config.timeLimit, isNull);
      expect(config.scoreLimit, isNull);
      expect(config.totalMatches, isNull);
    });
  });

  group('GameMode Enum Tests', () {
    test('should have correct values', () {
      expect(GameMode.values.length, equals(1));
      expect(GameMode.values, contains(GameMode.tournament));
    });
  });

  group('EndCondition Enum Tests', () {
    test('should have correct values', () {
      expect(EndCondition.values.length, equals(4));
      expect(EndCondition.values, contains(EndCondition.none));
      expect(EndCondition.values, contains(EndCondition.time));
      expect(EndCondition.values, contains(EndCondition.score));
      expect(EndCondition.values, contains(EndCondition.both));
    });
  });
}
