import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';

void main() {
  group('CurrentGameProvider Tests', () {
    late CurrentGameNotifier currentGameNotifier;
    late MatchesNotifier matchesNotifier;
    late TeamsNotifier teamsNotifier;
    late Team teamA;
    late Team teamB;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test');
      await HiveService.init(isTest: true);
    });

    setUp(() async {
      // Clear any existing data
      if (Hive.isBoxOpen('teams')) {
        await Hive.box('teams').clear();
      }
      if (Hive.isBoxOpen('matches')) {
        await Hive.box('matches').clear();
      }

      currentGameNotifier = CurrentGameNotifier();
      matchesNotifier = MatchesNotifier();
      teamsNotifier = TeamsNotifier();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 200));

      // Create test teams
      teamA = await teamsNotifier.createTeam(
        name: 'Team A',
        color: Colors.blue,
      );
      teamB = await teamsNotifier.createTeam(
        name: 'Team B',
        color: Colors.red,
      );
    });

    tearDown(() async {
      // Dispose notifiers first
      currentGameNotifier.dispose();
      matchesNotifier.dispose();
      teamsNotifier.dispose();

      // Clear boxes
      if (Hive.isBoxOpen('teams')) {
        await Hive.box('teams').clear();
      }
      if (Hive.isBoxOpen('matches')) {
        await Hive.box('matches').clear();
      }
    });

    tearDownAll(() async {
      // Close all boxes
      await Hive.close();
    });

    test('should initialize with idle state', () {
      expect(currentGameNotifier.gameState, equals(GameState.idle));
      expect(currentGameNotifier.isLoading, isFalse);
      expect(currentGameNotifier.error, isNull);
      expect(currentGameNotifier.elapsedSeconds, equals(0));
    });

    test('should start free game successfully', () async {
      // Act
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );

      // Assert
      expect(currentGameNotifier.gameState, equals(GameState.playing));
      expect(currentGameNotifier.isLoading, isFalse);
      expect(currentGameNotifier.error, isNull);
    });

    test('should pause game correctly', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );

      // Act
      currentGameNotifier.pauseGame();

      // Assert
      expect(currentGameNotifier.gameState, equals(GameState.paused));
    });

    test('should resume game correctly', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );
      currentGameNotifier.pauseGame();

      // Act
      currentGameNotifier.resumeGame();

      // Assert
      expect(currentGameNotifier.gameState, equals(GameState.playing));
    });

    test('should finish game correctly', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );

      // Act
      final match = Match.create(
        teamA: teamA,
        teamB: teamB,
      );
      await currentGameNotifier.endGame(
        match: match,
        matchesNotifier: matchesNotifier,
      );

      // Assert
      expect(currentGameNotifier.gameState, equals(GameState.finished));
    });

    test('should reset game to idle state', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );
      final match = Match.create(
        teamA: teamA,
        teamB: teamB,
      );
      await currentGameNotifier.endGame(
        match: match,
        matchesNotifier: matchesNotifier,
      );

      // Act
      currentGameNotifier.resetGameState();

      // Assert
      expect(currentGameNotifier.gameState, equals(GameState.idle));
      expect(currentGameNotifier.elapsedSeconds, equals(0));
    });

    test('should track elapsed time when playing', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );

      // Act
      await Future.delayed(
          const Duration(milliseconds: 1100)); // Wait a bit more than 1 second

      // Assert
      expect(currentGameNotifier.elapsedSeconds, greaterThan(0));
    });

    test('should not track time when paused', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      currentGameNotifier.pauseGame();
      final elapsedWhenPaused = currentGameNotifier.elapsedSeconds;

      // Act
      await Future.delayed(const Duration(milliseconds: 1000));

      // Assert
      expect(currentGameNotifier.elapsedSeconds, equals(elapsedWhenPaused));
    });

    test('should handle loading state correctly', () async {
      // Arrange
      var loadingStates = <bool>[];
      currentGameNotifier.addListener(() {
        loadingStates.add(currentGameNotifier.isLoading);
      });

      // Act
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );

      // Assert
      expect(loadingStates,
          contains(true)); // Should have been loading at some point
      expect(currentGameNotifier.isLoading,
          isFalse); // Should not be loading at the end
    });

    test('should notify listeners on state changes', () async {
      // Arrange
      var notificationCount = 0;
      currentGameNotifier.addListener(() {
        notificationCount++;
      });

      // Act
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );
      currentGameNotifier.pauseGame();
      currentGameNotifier.resumeGame();

      // Assert
      expect(notificationCount, greaterThan(0));
    });

    test('should handle errors gracefully', () {
      // Test that error handling structure exists
      expect(currentGameNotifier.error, isNull);
    });

    test('should not start game when already playing', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );
      expect(currentGameNotifier.gameState, equals(GameState.playing));

      // Act & Assert
      // Starting another game should not change the state or cause issues
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );

      expect(currentGameNotifier.gameState, equals(GameState.playing));
    });

    test('should not pause when not playing', () {
      // Arrange - game is in idle state
      expect(currentGameNotifier.gameState, equals(GameState.idle));

      // Act
      currentGameNotifier.pauseGame();

      // Assert - state should remain idle
      expect(currentGameNotifier.gameState, equals(GameState.idle));
    });

    test('should not resume when not paused', () async {
      // Arrange
      await currentGameNotifier.startFreeGame(
        teamA: teamA,
        teamB: teamB,
        matchesNotifier: matchesNotifier,
      );
      expect(currentGameNotifier.gameState, equals(GameState.playing));

      // Act
      currentGameNotifier.resumeGame();

      // Assert - state should remain playing
      expect(currentGameNotifier.gameState, equals(GameState.playing));
    });
  });
}
