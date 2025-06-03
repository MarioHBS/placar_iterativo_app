import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/tournament.dart';

void main() {
  group('HiveService Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test');
    });

    tearDownAll(() async {
      await Hive.close();
    });

    test('should initialize Hive successfully', () async {
      // Act
      await HiveService.init(isTest: true);

      // Assert
      expect(Hive.isAdapterRegistered(1), isTrue); // Team adapter
      expect(Hive.isAdapterRegistered(2), isTrue); // GameMode adapter
      expect(Hive.isAdapterRegistered(3), isTrue); // EndCondition adapter
      expect(Hive.isAdapterRegistered(4), isTrue); // GameConfig adapter
      expect(Hive.isAdapterRegistered(5), isTrue); // Match adapter
      expect(Hive.isAdapterRegistered(100), isTrue); // Color adapter
      expect(Hive.isAdapterRegistered(101), isTrue); // DateTime adapter
    });

    test('should register all model adapters', () async {
      // Arrange & Act
      await HiveService.init(isTest: true);

      // Assert - Check that all required adapters are registered
      expect(Hive.isAdapterRegistered(1), isTrue); // Team
      expect(Hive.isAdapterRegistered(2), isTrue); // GameMode
      expect(Hive.isAdapterRegistered(3), isTrue); // EndCondition
      expect(Hive.isAdapterRegistered(4), isTrue); // GameConfig
      expect(Hive.isAdapterRegistered(5), isTrue); // Match
    });

    test('should register custom type adapters', () async {
      // Arrange & Act
      await HiveService.init(isTest: true);

      // Assert
      expect(Hive.isAdapterRegistered(100), isTrue); // Color adapter
      expect(Hive.isAdapterRegistered(101), isTrue); // DateTime adapter
    });

    test('should handle multiple initializations gracefully', () async {
      // Act
      await HiveService.init(isTest: true);
      await HiveService.init(isTest: true); // Second initialization
      await HiveService.init(isTest: true); // Third initialization

      // Assert - Should not throw errors
      expect(Hive.isAdapterRegistered(1), isTrue);
      expect(Hive.isAdapterRegistered(100), isTrue);
    });

    group('Color Adapter Tests', () {
      late Box<Color> colorBox;

      setUp(() async {
        await HiveService.init(isTest: true);
        colorBox = await Hive.openBox<Color>('test_colors');
      });

      tearDown(() async {
        await colorBox.clear();
        await colorBox.close();
      });

      test('should serialize and deserialize Color correctly', () async {
        // Arrange
        const testColor = Colors.blue;
        const key = 'test_color';

        // Act
        await colorBox.put(key, testColor);
        final retrievedColor = colorBox.get(key);

        // Assert
        expect(retrievedColor, equals(testColor));
        expect(retrievedColor?.value, equals(testColor.value));
      });

      test('should handle custom colors', () async {
        // Arrange
        const customColor = Color(0xFF123456);
        const key = 'custom_color';

        // Act
        await colorBox.put(key, customColor);
        final retrievedColor = colorBox.get(key);

        // Assert
        expect(retrievedColor, equals(customColor));
        expect(retrievedColor?.value, equals(0xFF123456));
      });

      test('should handle transparent colors', () async {
        // Arrange
        const transparentColor = Colors.transparent;
        const key = 'transparent_color';

        // Act
        await colorBox.put(key, transparentColor);
        final retrievedColor = colorBox.get(key);

        // Assert
        expect(retrievedColor, equals(transparentColor));
        expect(retrievedColor?.alpha, equals(0));
      });
    });

    group('DateTime Adapter Tests', () {
      late Box<DateTime> dateTimeBox;

      setUp(() async {
        await HiveService.init(isTest: true);
        dateTimeBox = await Hive.openBox<DateTime>('test_datetimes');
      });

      tearDown(() async {
        await dateTimeBox.clear();
        await dateTimeBox.close();
      });

      test('should serialize and deserialize DateTime correctly', () async {
        // Arrange
        final testDateTime = DateTime(2024, 1, 15, 10, 30, 45);
        const key = 'test_datetime';

        // Act
        await dateTimeBox.put(key, testDateTime);
        final retrievedDateTime = dateTimeBox.get(key);

        // Assert
        expect(retrievedDateTime, equals(testDateTime));
        expect(retrievedDateTime?.year, equals(2024));
        expect(retrievedDateTime?.month, equals(1));
        expect(retrievedDateTime?.day, equals(15));
        expect(retrievedDateTime?.hour, equals(10));
        expect(retrievedDateTime?.minute, equals(30));
        expect(retrievedDateTime?.second, equals(45));
      });

      test('should handle current DateTime', () async {
        // Arrange
        final now = DateTime.now();
        const key = 'current_datetime';

        // Act
        await dateTimeBox.put(key, now);
        final retrievedDateTime = dateTimeBox.get(key);

        // Assert
        expect(retrievedDateTime, equals(now));
      });

      test('should handle UTC DateTime', () async {
        // Arrange
        final utcDateTime = DateTime.utc(2024, 6, 15, 12, 0, 0);
        const key = 'utc_datetime';

        // Act
        await dateTimeBox.put(key, utcDateTime);
        final retrievedDateTime = dateTimeBox.get(key);

        // Assert
        expect(retrievedDateTime, equals(utcDateTime));
        expect(retrievedDateTime?.isUtc, isTrue);
      });

      test('should handle DateTime with milliseconds', () async {
        // Arrange
        final dateTimeWithMillis = DateTime(2024, 1, 1, 0, 0, 0, 123);
        const key = 'datetime_with_millis';

        // Act
        await dateTimeBox.put(key, dateTimeWithMillis);
        final retrievedDateTime = dateTimeBox.get(key);

        // Assert
        expect(retrievedDateTime, equals(dateTimeWithMillis));
        expect(retrievedDateTime?.millisecond, equals(123));
      });
    });

    group('Model Integration Tests', () {
      late Box<Team> teamBox;
      late Box<Match> matchBox;
      late Box<GameConfig> gameConfigBox;

      setUp(() async {
        await HiveService.init(isTest: true);
        teamBox = await Hive.openBox<Team>('test_teams');
        matchBox = await Hive.openBox<Match>('test_matches');
        gameConfigBox = await Hive.openBox<GameConfig>('test_game_configs');
      });

      tearDown(() async {
        await teamBox.clear();
        await matchBox.clear();
        await gameConfigBox.clear();
        await teamBox.close();
        await matchBox.close();
        await gameConfigBox.close();
      });

      test('should store and retrieve Team objects', () async {
        // Arrange
        final team = Team(
          id: 'team-1',
          name: 'Test Team',
          color: Colors.blue,
          members: ['Player 1', 'Player 2'],
          emoji: '⚽',
          wins: 5,
          losses: 2,
        );

        // Act
        await teamBox.put(team.id, team);
        final retrievedTeam = teamBox.get(team.id);

        // Assert
        expect(retrievedTeam, isNotNull);
        expect(retrievedTeam?.id, equals(team.id));
        expect(retrievedTeam?.name, equals(team.name));
        expect(retrievedTeam?.color, equals(team.color));
        expect(retrievedTeam?.members, equals(team.members));
        expect(retrievedTeam?.emoji, equals(team.emoji));
        expect(retrievedTeam?.wins, equals(team.wins));
        expect(retrievedTeam?.losses, equals(team.losses));
      });

      test('should store and retrieve Match objects', () async {
        // Arrange
        final startTime = DateTime.now();
        final match = Match(
          id: 'match-1',
          teamAId: 'team-a',
          teamBId: 'team-b',
          teamAScore: 3,
          teamBScore: 2,
          startTime: startTime,
          durationInSeconds: 3600,
          isComplete: true,
          winnerId: 'team-a',
        );

        // Act
        await matchBox.put(match.id, match);
        final retrievedMatch = matchBox.get(match.id);

        // Assert
        expect(retrievedMatch, isNotNull);
        expect(retrievedMatch?.id, equals(match.id));
        expect(retrievedMatch?.teamAId, equals(match.teamAId));
        expect(retrievedMatch?.teamBId, equals(match.teamBId));
        expect(retrievedMatch?.teamAScore, equals(match.teamAScore));
        expect(retrievedMatch?.teamBScore, equals(match.teamBScore));
        expect(retrievedMatch?.startTime, equals(match.startTime));
        expect(
            retrievedMatch?.durationInSeconds, equals(match.durationInSeconds));
        expect(retrievedMatch?.isComplete, equals(match.isComplete));
        expect(retrievedMatch?.winnerId, equals(match.winnerId));
      });

      test('should store and retrieve GameConfig objects', () async {
        // Arrange
        final gameConfig = GameConfig(
          id: 'config-1',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.both,
          timeLimit: 1800,
          scoreLimit: 10,
          winsForWaitingMode: 5,
          totalMatches: 20,
        );

        // Act
        await gameConfigBox.put(gameConfig.id, gameConfig);
        final retrievedConfig = gameConfigBox.get(gameConfig.id);

        // Assert
        expect(retrievedConfig, isNotNull);
        expect(retrievedConfig?.id, equals(gameConfig.id));
        expect(retrievedConfig?.gameMode, equals(gameConfig.gameMode));
        expect(retrievedConfig?.endCondition, equals(gameConfig.endCondition));
        expect(retrievedConfig?.timeLimit, equals(gameConfig.timeLimit));
        expect(retrievedConfig?.scoreLimit, equals(gameConfig.scoreLimit));
        expect(retrievedConfig?.winsForWaitingMode,
            equals(gameConfig.winsForWaitingMode));
        expect(retrievedConfig?.totalMatches, equals(gameConfig.totalMatches));
      });
    });
  });
}
