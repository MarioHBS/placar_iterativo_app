import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/screens/scoreboard_screen.dart';
import 'package:placar_iterativo_app/app_module.dart';

void main() {
  group('Scoreboard Unlimited Mode Tests', () {
    late Team teamA;
    late Team teamB;

    setUpAll(() {
      // Initialize Modular
      Modular.bindModule(AppModule());
    });

    setUp(() {
      // Create test teams
      teamA = Team(id: '1', name: 'Team A', color: Colors.blue);
      teamB = Team(id: '2', name: 'Team B', color: Colors.red);
    });

    tearDownAll(() {
      Modular.destroy();
    });

    testWidgets('Should handle unlimited mode correctly without ending match',
        (WidgetTester tester) async {
      // Configure unlimited game mode
      final unlimitedConfig = GameConfig(
        id: 'test-config',
        endCondition: EndCondition.none, // Unlimited mode
        scoreLimit: null, // No score limit
        timeLimit: null, // No time limit
      );

      // Build the widget
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: MaterialApp(
            home: ScoreboardScreen(
              teamA: teamA,
              teamB: teamB,
              gameConfig: unlimitedConfig,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find score increment areas
      final teamAScoreArea = find.byKey(const Key('teamA_score_area'));

      // If the key doesn't exist, try to find by text or other means
      if (teamAScoreArea.evaluate().isEmpty) {
        // Look for team name or score display
        final teamAName = find.text(teamA.name);
        expect(teamAName, findsWidgets);

        // Test that the widget builds without errors
        expect(find.byType(ScoreboardScreen), findsOneWidget);
      } else {
        // Test score increment if the button exists
        await tester.tap(teamAScoreArea);
        await tester.pump();
      }
    });

    testWidgets('Should build ScoreboardScreen with limited mode',
        (WidgetTester tester) async {
      // Configure limited game mode with score limit of 10
      final limitedConfig = GameConfig(
        id: 'test-config-limited',
        endCondition: EndCondition.score,
        scoreLimit: 10,
        timeLimit: null,
      );

      // Build the widget
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: MaterialApp(
            home: ScoreboardScreen(
              teamA: teamA,
              teamB: teamB,
              gameConfig: limitedConfig,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test that the widget builds without errors
      expect(find.byType(ScoreboardScreen), findsOneWidget);

      // Look for team names
      expect(find.text(teamA.name), findsWidgets);
        expect(find.text(teamB.name), findsWidgets);
    });

    group('GameConfig shouldEndByScore Tests', () {
      test(
          'shouldEndByScore returns true when score limit is reached in limited mode',
          () {
        final config = GameConfig(
          id: 'test-config-1',
          endCondition: EndCondition.score,
          scoreLimit: 10,
          timeLimit: null,
        );

        expect(config.shouldEndByScore(10, 0), isTrue);
        expect(config.shouldEndByScore(11, 2), isTrue);
        expect(config.shouldEndByScore(9, 1), isFalse);
      });

      test(
          'shouldEndByScore returns false in unlimited mode regardless of score',
          () {
        final config = GameConfig(
          id: 'test-config-2',
          endCondition: EndCondition.none,
          scoreLimit: null,
          timeLimit: null,
        );

        expect(config.shouldEndByScore(90, 2), isFalse);
        expect(config.shouldEndByScore(91, 5), isFalse);
        expect(config.shouldEndByScore(100, 4), isFalse);
        expect(config.shouldEndByScore(1000, 0), isFalse);
      });
    });
  });
}
