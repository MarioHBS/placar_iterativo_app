import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/screens/scoreboard_screen.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';

import '../test_utils.dart';

void main() {
  group('ScoreboardScreen Orientation Tests', () {
    late Team teamA;
    late Team teamB;
    late Match match;
    late GameConfig gameConfig;
    late CurrentGameNotifier currentGameNotifier;
    late MatchesNotifier matchesNotifier;

    setUp(() {
      teamA = Team(
        id: 'team-a',
        name: 'Team A',
        color: Colors.blue,
        emoji: '⚽',
      );

      teamB = Team(
        id: 'team-b',
        name: 'Team B',
        color: Colors.red,
        emoji: '🏀',
      );

      match = Match(
        id: 'match-1',
        teamAId: teamA.id,
        teamBId: teamB.id,
        teamAScore: 0,
        teamBScore: 0,
        startTime: DateTime.now(),
      );

      gameConfig = GameConfig.tournamentMode(
        scoreLimit: 10,
        timeLimit: 300, // 5 minutes
      );

      currentGameNotifier = CurrentGameNotifier();
      matchesNotifier = MatchesNotifier();

      // Setup Modular bindings
      Modular.bindModule(TestModule());
    });

    tearDown(() {
      Modular.destroy();
    });

    testWidgets('should display orientation controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(
          ScoreboardScreen(
            match: match,
            teamA: teamA,
            teamB: teamB,
            gameConfig: gameConfig,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify orientation control buttons are present
      expect(find.byIcon(Icons.stay_current_portrait), findsOneWidget);
      expect(find.byIcon(Icons.stay_current_landscape), findsOneWidget);
      expect(find.byIcon(Icons.screen_rotation), findsOneWidget);
    });

    testWidgets('should handle portrait orientation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(
          ScoreboardScreen(
            match: match,
            teamA: teamA,
            teamB: teamB,
            gameConfig: gameConfig,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test portrait layout
      await TestUtils.changeOrientation(tester, Orientation.portrait);
      await tester.pumpAndSettle();

      // Verify teams are arranged vertically in portrait mode
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should handle landscape orientation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(
          ScoreboardScreen(
            match: match,
            teamA: teamA,
            teamB: teamB,
            gameConfig: gameConfig,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test landscape layout
      await TestUtils.changeOrientation(tester, Orientation.landscape);
      await tester.pumpAndSettle();

      // Verify teams are arranged horizontally in landscape mode
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should toggle orientation lock', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(
          ScoreboardScreen(
            match: match,
            teamA: teamA,
            teamB: teamB,
            gameConfig: gameConfig,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the orientation lock button
      final lockButton = find.byIcon(Icons.screen_rotation);
      expect(lockButton, findsOneWidget);

      await tester.tap(lockButton);
      await tester.pumpAndSettle();

      // Verify the icon changed to locked state
      expect(find.byIcon(Icons.screen_lock_rotation), findsOneWidget);
    });

    testWidgets('should force portrait orientation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(
          ScoreboardScreen(
            match: match,
            teamA: teamA,
            teamB: teamB,
            gameConfig: gameConfig,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the portrait button
      final portraitButton = find.byIcon(Icons.stay_current_portrait);
      expect(portraitButton, findsOneWidget);

      await tester.tap(portraitButton);
      await tester.pumpAndSettle();

      // Verify orientation lock is enabled
      expect(find.byIcon(Icons.screen_lock_rotation), findsOneWidget);
    });

    testWidgets('should force landscape orientation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(
          ScoreboardScreen(
            match: match,
            teamA: teamA,
            teamB: teamB,
            gameConfig: gameConfig,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the landscape button
      final landscapeButton = find.byIcon(Icons.stay_current_landscape);
      expect(landscapeButton, findsOneWidget);

      await tester.tap(landscapeButton);
      await tester.pumpAndSettle();

      // Verify orientation lock is enabled
      expect(find.byIcon(Icons.screen_lock_rotation), findsOneWidget);
    });
  });
}

class TestModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<CurrentGameNotifier>(() => CurrentGameNotifier());
    i.addSingleton<MatchesNotifier>(() => MatchesNotifier());
  }
}
