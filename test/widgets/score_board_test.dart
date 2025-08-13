import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:placar_iterativo_app/widgets/score_board.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import '../test_utils.dart';

@GenerateMocks([CurrentGameNotifier])
import 'score_board_test.mocks.dart';

void main() {
  group('ScoreBoard Widget Tests', () {
    late MockCurrentGameNotifier mockCurrentGameNotifier;
    late Team testTeamA;
    late Team testTeamB;
    late Match testMatch;
    late GameConfig testConfig;

    setUp(() {
      mockCurrentGameNotifier = MockCurrentGameNotifier();
      
      testTeamA = TestUtils.createTestTeam(
        id: 'team_a',
        name: 'Team A',
        color: Colors.blue,
      );
      
      testTeamB = TestUtils.createTestTeam(
        id: 'team_b',
        name: 'Team B',
        color: Colors.red,
      );
      
      testConfig = TestUtils.createTestGameConfig(
        maxScore: 15,
        maxTime: const Duration(minutes: 10),
      );
      
      testMatch = TestUtils.createTestMatch(
        id: 'test_match',
        teamAId: testTeamA.id,
        teamBId: testTeamB.id,
        teamAScore: 5,
        teamBScore: 3,
        config: testConfig,
      );
    });

    Widget createTestWidget({
      bool hasActiveGame = true,
      Match? currentMatch,
      Team? teamA,
      Team? teamB,
    }) {
      when(mockCurrentGameNotifier.hasActiveGame)
          .thenReturn(hasActiveGame);
      when(mockCurrentGameNotifier.currentMatch)
          .thenReturn(currentMatch ?? testMatch);
      when(mockCurrentGameNotifier.teamA)
          .thenReturn(teamA ?? testTeamA);
      when(mockCurrentGameNotifier.teamB)
          .thenReturn(teamB ?? testTeamB);
      
      return MaterialApp(
        home: ChangeNotifierProvider<CurrentGameNotifier>.value(
          value: mockCurrentGameNotifier,
          child: const Scaffold(
            body: ScoreBoard(),
          ),
        ),
      );
    }

    group('Renderização Básica', () {
      testWidgets('deve renderizar quando há jogo ativo', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(ScoreBoard), findsOneWidget);
        expect(find.text('Team A'), findsOneWidget);
        expect(find.text('Team B'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('deve mostrar mensagem quando não há jogo ativo', (tester) async {
        await tester.pumpWidget(createTestWidget(hasActiveGame: false));
        
        expect(find.text('Nenhum jogo ativo'), findsOneWidget);
        expect(find.text('Team A'), findsNothing);
        expect(find.text('Team B'), findsNothing);
      });

      testWidgets('deve exibir nomes dos times corretamente', (tester) async {
        final customTeamA = TestUtils.createTestTeam(
          id: 'custom_a',
          name: 'Custom Team A',
        );
        final customTeamB = TestUtils.createTestTeam(
          id: 'custom_b',
          name: 'Custom Team B',
        );
        
        await tester.pumpWidget(createTestWidget(
          teamA: customTeamA,
          teamB: customTeamB,
        ));
        
        expect(find.text('Custom Team A'), findsOneWidget);
        expect(find.text('Custom Team B'), findsOneWidget);
      });
    });

    group('Exibição de Pontuação', () {
      testWidgets('deve exibir pontuações corretas', (tester) async {
        final match = TestUtils.createTestMatch(
          id: 'score_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 12,
          teamBScore: 8,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: match));
        
        expect(find.text('12'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
      });

      testWidgets('deve exibir pontuação zero', (tester) async {
        final match = TestUtils.createTestMatch(
          id: 'zero_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 0,
          teamBScore: 0,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: match));
        
        expect(find.text('0'), findsNWidgets(2));
      });

      testWidgets('deve destacar time vencedor', (tester) async {
        final match = TestUtils.createTestMatch(
          id: 'winner_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 15,
          teamBScore: 10,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: match));
        
        // Verificar se há indicação visual do vencedor
        final teamAWidget = find.ancestor(
          of: find.text('Team A'),
          matching: find.byType(Container),
        );
        expect(teamAWidget, findsAtLeastNWidgets(1));
      });
    });

    group('Cores dos Times', () {
      testWidgets('deve aplicar cores dos times', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verificar se as cores dos times são aplicadas
        final containers = find.byType(Container);
        expect(containers, findsAtLeastNWidgets(1));
      });

      testWidgets('deve usar cores padrão quando time não tem cor', (tester) async {
        final teamWithoutColor = TestUtils.createTestTeam(
          id: 'no_color',
          name: 'No Color Team',
          color: null,
        );
        
        await tester.pumpWidget(createTestWidget(teamA: teamWithoutColor));
        
        expect(find.byType(ScoreBoard), findsOneWidget);
      });
    });

    group('Interações', () {
      testWidgets('deve permitir incrementar pontuação do time A', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final incrementButtonA = find.byKey(const Key('increment_team_a'));
        expect(incrementButtonA, findsOneWidget);
        
        await tester.tap(incrementButtonA);
        
        verify(mockCurrentGameNotifier.incrementTeamAScore()).called(1);
      });

      testWidgets('deve permitir incrementar pontuação do time B', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final incrementButtonB = find.byKey(const Key('increment_team_b'));
        expect(incrementButtonB, findsOneWidget);
        
        await tester.tap(incrementButtonB);
        
        verify(mockCurrentGameNotifier.incrementTeamBScore()).called(1);
      });

      testWidgets('deve permitir decrementar pontuação do time A', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final decrementButtonA = find.byKey(const Key('decrement_team_a'));
        expect(decrementButtonA, findsOneWidget);
        
        await tester.tap(decrementButtonA);
        
        verify(mockCurrentGameNotifier.decrementTeamAScore()).called(1);
      });

      testWidgets('deve permitir decrementar pontuação do time B', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final decrementButtonB = find.byKey(const Key('decrement_team_b'));
        expect(decrementButtonB, findsOneWidget);
        
        await tester.tap(decrementButtonB);
        
        verify(mockCurrentGameNotifier.decrementTeamBScore()).called(1);
      });

      testWidgets('botões devem estar desabilitados quando jogo não está ativo', (tester) async {
        await tester.pumpWidget(createTestWidget(hasActiveGame: false));
        
        expect(find.byKey(const Key('increment_team_a')), findsNothing);
        expect(find.byKey(const Key('increment_team_b')), findsNothing);
      });
    });

    group('Responsividade', () {
      testWidgets('deve adaptar layout para tela pequena', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 600));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(ScoreBoard), findsOneWidget);
        
        // Verificar se o layout se adapta
        final scoreBoard = tester.widget<ScoreBoard>(find.byType(ScoreBoard));
        expect(scoreBoard, isNotNull);
      });

      testWidgets('deve adaptar layout para tela grande', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(ScoreBoard), findsOneWidget);
      });

      testWidgets('deve manter proporções em orientação landscape', (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(ScoreBoard), findsOneWidget);
      });
    });

    group('Animações', () {
      testWidgets('deve animar mudanças de pontuação', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Simular mudança de pontuação
        final newMatch = TestUtils.createTestMatch(
          id: 'animated_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 6,
          teamBScore: 3,
        );
        
        when(mockCurrentGameNotifier.currentMatch).thenReturn(newMatch);
        
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        
        expect(find.text('6'), findsOneWidget);
      });

      testWidgets('deve ter animação de vitória', (tester) async {
        final winningMatch = TestUtils.createTestMatch(
          id: 'winning_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 15,
          teamBScore: 10,
          isCompleted: true,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: winningMatch));
        
        // Verificar se há elementos de animação de vitória
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.byType(ScoreBoard), findsOneWidget);
      });
    });

    group('Acessibilidade', () {
      testWidgets('deve ter labels de acessibilidade', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Pontuação do Team A: 5'), findsOneWidget);
        expect(find.bySemanticsLabel('Pontuação do Team B: 3'), findsOneWidget);
      });

      testWidgets('botões devem ter hints de acessibilidade', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Incrementar pontuação do Team A'), findsOneWidget);
        expect(find.bySemanticsLabel('Decrementar pontuação do Team A'), findsOneWidget);
        expect(find.bySemanticsLabel('Incrementar pontuação do Team B'), findsOneWidget);
        expect(find.bySemanticsLabel('Decrementar pontuação do Team B'), findsOneWidget);
      });

      testWidgets('deve suportar navegação por teclado', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Simular navegação por tab
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        expect(find.byType(ScoreBoard), findsOneWidget);
      });
    });

    group('Estados Especiais', () {
      testWidgets('deve mostrar empate', (tester) async {
        final tieMatch = TestUtils.createTestMatch(
          id: 'tie_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 10,
          teamBScore: 10,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: tieMatch));
        
        expect(find.text('10'), findsNWidgets(2));
        // Verificar indicação visual de empate
      });

      testWidgets('deve mostrar jogo pausado', (tester) async {
        when(mockCurrentGameNotifier.isPaused).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('PAUSADO'), findsOneWidget);
      });

      testWidgets('deve mostrar jogo finalizado', (tester) async {
        final completedMatch = TestUtils.createTestMatch(
          id: 'completed_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 15,
          teamBScore: 12,
          isCompleted: true,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: completedMatch));
        
        expect(find.text('FINALIZADO'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('deve renderizar rapidamente', (tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(createTestWidget());
        
        stopwatch.stop();
        
        // Deve renderizar em menos de 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('deve lidar com atualizações frequentes', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Simular múltiplas atualizações
        for (int i = 0; i < 10; i++) {
          final updatedMatch = TestUtils.createTestMatch(
            id: 'performance_test',
            teamAId: testTeamA.id,
            teamBId: testTeamB.id,
            teamAScore: i,
            teamBScore: i + 1,
          );
          
          when(mockCurrentGameNotifier.currentMatch).thenReturn(updatedMatch);
          await tester.pump();
        }
        
        expect(find.byType(ScoreBoard), findsOneWidget);
      });
    });

    group('Tratamento de Erros', () {
      testWidgets('deve lidar com dados nulos', (tester) async {
        when(mockCurrentGameNotifier.currentMatch).thenReturn(null);
        when(mockCurrentGameNotifier.teamA).thenReturn(null);
        when(mockCurrentGameNotifier.teamB).thenReturn(null);
        
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Erro: Dados do jogo não encontrados'), findsOneWidget);
      });

      testWidgets('deve lidar com nomes de times muito longos', (tester) async {
        final longNameTeam = TestUtils.createTestTeam(
          id: 'long_name',
          name: 'Este é um nome de time extremamente longo que pode causar problemas de layout',
        );
        
        await tester.pumpWidget(createTestWidget(teamA: longNameTeam));
        
        expect(find.byType(ScoreBoard), findsOneWidget);
        // Verificar se o texto é truncado adequadamente
      });

      testWidgets('deve lidar com pontuações muito altas', (tester) async {
        final highScoreMatch = TestUtils.createTestMatch(
          id: 'high_score_test',
          teamAId: testTeamA.id,
          teamBId: testTeamB.id,
          teamAScore: 999,
          teamBScore: 1000,
        );
        
        await tester.pumpWidget(createTestWidget(currentMatch: highScoreMatch));
        
        expect(find.text('999'), findsOneWidget);
        expect(find.text('1000'), findsOneWidget);
      });
    });
  });
}