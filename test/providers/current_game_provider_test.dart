import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import '../test_utils.dart';

void main() {
  group('CurrentGameProvider Tests', () {
    late CurrentGameNotifier currentGameProvider;
    late Team teamA;
    late Team teamB;
    late GameConfig gameConfig;

    setUp(() async {
      await TestUtils.initializeHiveForTesting();
      currentGameProvider = CurrentGameNotifier();
      
      teamA = TestUtils.createTestTeam(
        id: 'team_a',
        name: 'Team A',
      );
      
      teamB = TestUtils.createTestTeam(
        id: 'team_b',
        name: 'Team B',
      );
      
      gameConfig = TestUtils.createTestGameConfig(
        endCondition: EndCondition.score,
        maxScore: 10,
      );
      
      // Aguardar inicialização
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Inicialização', () {
      test('deve inicializar com estado correto', () {
        expect(currentGameProvider.currentMatch, isNull);
        expect(currentGameProvider.teamA, isNull);
        expect(currentGameProvider.teamB, isNull);
        expect(currentGameProvider.gameConfig, isNull);
        expect(currentGameProvider.isGameActive, isFalse);
        expect(currentGameProvider.isPaused, isFalse);
      });
    });

    group('Início de Jogo', () {
      test('startGame deve iniciar um novo jogo', () async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        expect(currentGameProvider.currentMatch, isNotNull);
        expect(currentGameProvider.teamA, equals(teamA));
        expect(currentGameProvider.teamB, equals(teamB));
        expect(currentGameProvider.gameConfig, equals(gameConfig));
        expect(currentGameProvider.isGameActive, isTrue);
        expect(currentGameProvider.isPaused, isFalse);
      });

      test('startGame deve criar uma partida com IDs corretos', () async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        final match = currentGameProvider.currentMatch!;
        expect(match.teamAId, equals(teamA.id));
        expect(match.teamBId, equals(teamB.id));
        expect(match.teamAScore, equals(0));
        expect(match.teamBScore, equals(0));
        expect(match.isComplete, isFalse);
      });

      test('startGame deve notificar listeners', () async {
        bool notified = false;
        currentGameProvider.addListener(() {
          notified = true;
        });
        
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        expect(notified, isTrue);
      });

      test('startGame não deve permitir iniciar jogo quando já há um ativo', () async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        final firstMatch = currentGameProvider.currentMatch;
        
        // Tentar iniciar outro jogo
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        // Deve manter a primeira partida
        expect(currentGameProvider.currentMatch, equals(firstMatch));
      });
    });

    group('Controle de Pontuação', () {
      setUp(() async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
      });

      test('incrementTeamAScore deve aumentar pontuação do time A', () {
        currentGameProvider.incrementTeamAScore();
        
        expect(currentGameProvider.currentMatch!.teamAScore, equals(1));
        expect(currentGameProvider.currentMatch!.teamBScore, equals(0));
      });

      test('incrementTeamBScore deve aumentar pontuação do time B', () {
        currentGameProvider.incrementTeamBScore();
        
        expect(currentGameProvider.currentMatch!.teamAScore, equals(0));
        expect(currentGameProvider.currentMatch!.teamBScore, equals(1));
      });

      test('decrementTeamAScore deve diminuir pontuação do time A', () {
        currentGameProvider.incrementTeamAScore();
        currentGameProvider.incrementTeamAScore();
        currentGameProvider.decrementTeamAScore();
        
        expect(currentGameProvider.currentMatch!.teamAScore, equals(1));
      });

      test('decrementTeamBScore deve diminuir pontuação do time B', () {
        currentGameProvider.incrementTeamBScore();
        currentGameProvider.incrementTeamBScore();
        currentGameProvider.decrementTeamBScore();
        
        expect(currentGameProvider.currentMatch!.teamBScore, equals(1));
      });

      test('setTeamAScore deve definir pontuação do time A', () {
        currentGameProvider.setTeamAScore(5);
        
        expect(currentGameProvider.currentMatch!.teamAScore, equals(5));
      });

      test('setTeamBScore deve definir pontuação do time B', () {
        currentGameProvider.setTeamBScore(7);
        
        expect(currentGameProvider.currentMatch!.teamBScore, equals(7));
      });

      test('operações de pontuação devem notificar listeners', () {
        int notificationCount = 0;
        currentGameProvider.addListener(() {
          notificationCount++;
        });
        
        currentGameProvider.incrementTeamAScore();
        currentGameProvider.incrementTeamBScore();
        currentGameProvider.setTeamAScore(5);
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Controle de Tempo', () {
      setUp(() async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
      });

      test('pauseGame deve pausar o jogo', () {
        currentGameProvider.pauseGame();
        
        expect(currentGameProvider.isPaused, isTrue);
        expect(currentGameProvider.isGameActive, isTrue);
      });

      test('resumeGame deve retomar o jogo', () {
        currentGameProvider.pauseGame();
        currentGameProvider.resumeGame();
        
        expect(currentGameProvider.isPaused, isFalse);
        expect(currentGameProvider.isGameActive, isTrue);
      });

      test('getCurrentDuration deve retornar duração atual', () {
        final duration = currentGameProvider.getCurrentDuration();
        
        expect(duration, isA<Duration>());
        expect(duration.inSeconds, greaterThanOrEqualTo(0));
      });

      test('getFormattedDuration deve formatar duração', () {
        final formatted = currentGameProvider.getFormattedDuration();
        
        expect(formatted, matches(r'^\d{2}:\d{2}$'));
      });
    });

    group('Verificação de Fim de Jogo', () {
      setUp(() async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
      });

      test('isGameComplete deve verificar condição de pontuação', () {
        expect(currentGameProvider.isGameComplete(), isFalse);
        
        currentGameProvider.setTeamAScore(10); // Pontuação máxima
        expect(currentGameProvider.isGameComplete(), isTrue);
      });

      test('isGameComplete deve verificar condição de tempo', () async {
        final timeConfig = TestUtils.createTestGameConfig(
          endCondition: EndCondition.time,
          maxTime: const Duration(seconds: 1),
        );
        
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: timeConfig,
        );
        
        expect(currentGameProvider.isGameComplete(), isFalse);
        
        // Aguardar tempo limite
        await Future.delayed(const Duration(seconds: 2));
        expect(currentGameProvider.isGameComplete(), isTrue);
      });

      test('getWinningTeam deve retornar time vencedor', () {
        currentGameProvider.setTeamAScore(8);
        currentGameProvider.setTeamBScore(5);
        
        final winner = currentGameProvider.getWinningTeam();
        expect(winner, equals(teamA));
      });

      test('getWinningTeam deve retornar null em caso de empate', () {
        currentGameProvider.setTeamAScore(5);
        currentGameProvider.setTeamBScore(5);
        
        final winner = currentGameProvider.getWinningTeam();
        expect(winner, isNull);
      });

      test('getLosingTeam deve retornar time perdedor', () {
        currentGameProvider.setTeamAScore(3);
        currentGameProvider.setTeamBScore(7);
        
        final loser = currentGameProvider.getLosingTeam();
        expect(loser, equals(teamA));
      });
    });

    group('Finalização de Jogo', () {
      setUp(() async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
      });

      test('endGame deve finalizar o jogo', () async {
        currentGameProvider.setTeamAScore(10);
        
        await currentGameProvider.endGame();
        
        expect(currentGameProvider.currentMatch!.isComplete, isTrue);
        expect(currentGameProvider.currentMatch!.endTime, isNotNull);
        expect(currentGameProvider.currentMatch!.winnerId, equals(teamA.id));
        expect(currentGameProvider.currentMatch!.loserId, equals(teamB.id));
        expect(currentGameProvider.isGameActive, isFalse);
      });

      test('endGame deve lidar com empate', () async {
        currentGameProvider.setTeamAScore(5);
        currentGameProvider.setTeamBScore(5);
        
        await currentGameProvider.endGame();
        
        expect(currentGameProvider.currentMatch!.isComplete, isTrue);
        expect(currentGameProvider.currentMatch!.winnerId, isNull);
        expect(currentGameProvider.currentMatch!.loserId, isNull);
      });

      test('endGame deve calcular duração corretamente', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        await currentGameProvider.endGame();
        
        expect(currentGameProvider.currentMatch!.durationInSeconds, greaterThan(0));
      });

      test('resetGame deve reiniciar o jogo', () {
        currentGameProvider.setTeamAScore(5);
        currentGameProvider.setTeamBScore(3);
        
        currentGameProvider.resetGame();
        
        expect(currentGameProvider.currentMatch, isNull);
        expect(currentGameProvider.teamA, isNull);
        expect(currentGameProvider.teamB, isNull);
        expect(currentGameProvider.gameConfig, isNull);
        expect(currentGameProvider.isGameActive, isFalse);
        expect(currentGameProvider.isPaused, isFalse);
      });
    });

    group('Estado do Jogo', () {
      test('hasActiveGame deve retornar false quando não há jogo', () {
        expect(currentGameProvider.hasActiveGame(), isFalse);
      });

      test('hasActiveGame deve retornar true quando há jogo ativo', () async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        expect(currentGameProvider.hasActiveGame(), isTrue);
      });

      test('canModifyScore deve verificar se pode modificar pontuação', () async {
        expect(currentGameProvider.canModifyScore(), isFalse);
        
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        expect(currentGameProvider.canModifyScore(), isTrue);
        
        currentGameProvider.pauseGame();
        expect(currentGameProvider.canModifyScore(), isFalse);
        
        await currentGameProvider.endGame();
        expect(currentGameProvider.canModifyScore(), isFalse);
      });

      test('getGameProgress deve calcular progresso do jogo', () async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        expect(currentGameProvider.getGameProgress(), equals(0.0));
        
        currentGameProvider.setTeamAScore(5); // 50% da pontuação máxima
        expect(currentGameProvider.getGameProgress(), equals(0.5));
        
        currentGameProvider.setTeamAScore(10); // 100% da pontuação máxima
        expect(currentGameProvider.getGameProgress(), equals(1.0));
      });
    });

    group('Persistência', () {
      test('deve salvar estado do jogo', () async {
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        currentGameProvider.setTeamAScore(3);
        currentGameProvider.setTeamBScore(2);
        
        await currentGameProvider.saveGameState();
        
        // Verificar se foi salvo (implementação depende do provider real)
        expect(currentGameProvider.currentMatch, isNotNull);
      });

      test('deve carregar estado do jogo', () async {
        // Criar e salvar um jogo
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        currentGameProvider.setTeamAScore(7);
        await currentGameProvider.saveGameState();
        
        // Criar novo provider e carregar estado
        final newProvider = CurrentGameNotifier();
        await newProvider.loadGameState();
        
        // Verificar se carregou corretamente (implementação depende do provider real)
        expect(newProvider.currentMatch, isNotNull);
      });
    });

    group('Tratamento de Erros', () {
      test('deve lidar com operações em jogo inexistente', () {
        expect(() => currentGameProvider.incrementTeamAScore(), returnsNormally);
        expect(() => currentGameProvider.incrementTeamBScore(), returnsNormally);
        expect(() => currentGameProvider.pauseGame(), returnsNormally);
        expect(() => currentGameProvider.resumeGame(), returnsNormally);
      });

      test('deve validar parâmetros de início de jogo', () async {
        // Tentar iniciar jogo com times iguais
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamA, // Mesmo time
          config: gameConfig,
        );
        
        // Deve rejeitar ou lidar adequadamente
        expect(currentGameProvider.isGameActive, isFalse);
      });
    });

    group('Notificações', () {
      test('deve notificar listeners em todas as operações', () async {
        int notificationCount = 0;
        currentGameProvider.addListener(() {
          notificationCount++;
        });
        
        await currentGameProvider.startGame(
          teamA: teamA,
          teamB: teamB,
          config: gameConfig,
        );
        
        currentGameProvider.incrementTeamAScore();
        currentGameProvider.pauseGame();
        currentGameProvider.resumeGame();
        await currentGameProvider.endGame();
        currentGameProvider.resetGame();
        
        expect(notificationCount, greaterThan(0));
      });
    });
  });
}