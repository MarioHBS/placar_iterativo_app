import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import '../test_utils.dart';

void main() {
  group('MatchesProvider Tests', () {
    late MatchesNotifier matchesProvider;
    late List<Team> testTeams;
    late GameConfig gameConfig;

    setUp(() async {
      await TestUtils.initializeHiveForTesting();
      matchesProvider = MatchesNotifier();
      
      testTeams = [
        TestUtils.createTestTeam(id: 'team1', name: 'Team 1'),
        TestUtils.createTestTeam(id: 'team2', name: 'Team 2'),
        TestUtils.createTestTeam(id: 'team3', name: 'Team 3'),
        TestUtils.createTestTeam(id: 'team4', name: 'Team 4'),
      ];
      
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
        expect(matchesProvider.matches, isEmpty);
        expect(matchesProvider.activeMatches, isEmpty);
        expect(matchesProvider.completedMatches, isEmpty);
        expect(matchesProvider.matchCount, equals(0));
      });

      test('deve carregar partidas existentes', () async {
        // Criar e salvar uma partida
        final match = TestUtils.createTestMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        await matchesProvider.addMatch(match);
        
        // Criar novo provider e verificar carregamento
        final newProvider = MatchesNotifier();
        await newProvider.loadMatches();
        
        expect(newProvider.matches, isNotEmpty);
      });
    });

    group('Criação de Partidas', () {
      test('createMatch deve criar nova partida', () async {
        final match = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        expect(match, isNotNull);
        expect(match.teamAId, equals(testTeams[0].id));
        expect(match.teamBId, equals(testTeams[1].id));
        expect(match.teamAScore, equals(0));
        expect(match.teamBScore, equals(0));
        expect(match.isComplete, isFalse);
        expect(match.startTime, isNotNull);
        expect(matchesProvider.matches, contains(match));
      });

      test('createMatch deve gerar ID único', () async {
        final match1 = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        final match2 = await matchesProvider.createMatch(
          teamAId: testTeams[2].id,
          teamBId: testTeams[3].id,
        );
        
        expect(match1.id, isNot(equals(match2.id)));
      });

      test('createMatch deve notificar listeners', () async {
        bool notified = false;
        matchesProvider.addListener(() {
          notified = true;
        });
        
        await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        expect(notified, isTrue);
      });

      test('createMatch deve validar times diferentes', () async {
        expect(
          () => matchesProvider.createMatch(
            teamAId: testTeams[0].id,
            teamBId: testTeams[0].id, // Mesmo time
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Gerenciamento de Partidas', () {
      late Match testMatch;
      
      setUp(() async {
        testMatch = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
      });

      test('addMatch deve adicionar partida existente', () async {
        final newMatch = TestUtils.createTestMatch(
          teamAId: testTeams[2].id,
          teamBId: testTeams[3].id,
        );
        
        await matchesProvider.addMatch(newMatch);
        
        expect(matchesProvider.matches, contains(newMatch));
        expect(matchesProvider.matchCount, equals(2));
      });

      test('updateMatch deve atualizar partida existente', () async {
        testMatch.teamAScore = 5;
        testMatch.teamBScore = 3;
        
        await matchesProvider.updateMatch(testMatch);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamAScore, equals(5));
        expect(updatedMatch.teamBScore, equals(3));
      });

      test('deleteMatch deve remover partida', () async {
        await matchesProvider.deleteMatch(testMatch.id);
        
        expect(matchesProvider.matches, isNot(contains(testMatch)));
        expect(matchesProvider.getMatch(testMatch.id), isNull);
      });

      test('getMatch deve retornar partida por ID', () {
        final foundMatch = matchesProvider.getMatch(testMatch.id);
        
        expect(foundMatch, equals(testMatch));
      });

      test('getMatch deve retornar null para ID inexistente', () {
        final foundMatch = matchesProvider.getMatch('inexistente');
        
        expect(foundMatch, isNull);
      });
    });

    group('Controle de Pontuação', () {
      late Match testMatch;
      
      setUp(() async {
        testMatch = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
      });

      test('incrementTeamAScore deve aumentar pontuação do time A', () async {
        await matchesProvider.incrementTeamAScore(testMatch.id);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamAScore, equals(1));
      });

      test('incrementTeamBScore deve aumentar pontuação do time B', () async {
        await matchesProvider.incrementTeamBScore(testMatch.id);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamBScore, equals(1));
      });

      test('decrementTeamAScore deve diminuir pontuação do time A', () async {
        await matchesProvider.incrementTeamAScore(testMatch.id);
        await matchesProvider.incrementTeamAScore(testMatch.id);
        await matchesProvider.decrementTeamAScore(testMatch.id);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamAScore, equals(1));
      });

      test('decrementTeamBScore deve diminuir pontuação do time B', () async {
        await matchesProvider.incrementTeamBScore(testMatch.id);
        await matchesProvider.incrementTeamBScore(testMatch.id);
        await matchesProvider.decrementTeamBScore(testMatch.id);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamBScore, equals(1));
      });

      test('setTeamAScore deve definir pontuação do time A', () async {
        await matchesProvider.setTeamAScore(testMatch.id, 7);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamAScore, equals(7));
      });

      test('setTeamBScore deve definir pontuação do time B', () async {
        await matchesProvider.setTeamBScore(testMatch.id, 9);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamBScore, equals(9));
      });

      test('resetMatchScores deve zerar pontuações', () async {
        await matchesProvider.setTeamAScore(testMatch.id, 5);
        await matchesProvider.setTeamBScore(testMatch.id, 3);
        await matchesProvider.resetMatchScores(testMatch.id);
        
        final updatedMatch = matchesProvider.getMatch(testMatch.id);
        expect(updatedMatch!.teamAScore, equals(0));
        expect(updatedMatch!.teamBScore, equals(0));
      });
    });

    group('Finalização de Partidas', () {
      late Match testMatch;
      
      setUp(() async {
        testMatch = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
      });

      test('completeMatch deve finalizar partida com vencedor', () async {
        await matchesProvider.setTeamAScore(testMatch.id, 10);
        await matchesProvider.setTeamBScore(testMatch.id, 5);
        
        await matchesProvider.completeMatch(
          testMatch.id,
          winnerId: testTeams[0].id,
          loserId: testTeams[1].id,
        );
        
        final completedMatch = matchesProvider.getMatch(testMatch.id);
        expect(completedMatch!.isComplete, isTrue);
        expect(completedMatch.winnerId, equals(testTeams[0].id));
        expect(completedMatch.loserId, equals(testTeams[1].id));
        expect(completedMatch.endTime, isNotNull);
        expect(completedMatch.durationInSeconds, greaterThan(0));
      });

      test('completeMatch deve finalizar partida com empate', () async {
        await matchesProvider.setTeamAScore(testMatch.id, 5);
        await matchesProvider.setTeamBScore(testMatch.id, 5);
        
        await matchesProvider.completeMatch(testMatch.id);
        
        final completedMatch = matchesProvider.getMatch(testMatch.id);
        expect(completedMatch!.isComplete, isTrue);
        expect(completedMatch.winnerId, isNull);
        expect(completedMatch.loserId, isNull);
      });

      test('completeMatch deve calcular duração corretamente', () async {
        await Future.delayed(const Duration(milliseconds: 100));
        await matchesProvider.completeMatch(testMatch.id);
        
        final completedMatch = matchesProvider.getMatch(testMatch.id);
        expect(completedMatch!.durationInSeconds, greaterThan(0));
      });

      test('reopenMatch deve reabrir partida finalizada', () async {
        await matchesProvider.completeMatch(testMatch.id);
        await matchesProvider.reopenMatch(testMatch.id);
        
        final reopenedMatch = matchesProvider.getMatch(testMatch.id);
        expect(reopenedMatch!.isComplete, isFalse);
        expect(reopenedMatch.endTime, isNull);
        expect(reopenedMatch.winnerId, isNull);
        expect(reopenedMatch.loserId, isNull);
      });
    });

    group('Filtros e Consultas', () {
      setUp(() async {
        // Criar partidas ativas
        await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        await matchesProvider.createMatch(
          teamAId: testTeams[2].id,
          teamBId: testTeams[3].id,
        );
        
        // Criar e finalizar uma partida
        final completedMatch = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[2].id,
        );
        
        await matchesProvider.completeMatch(
          completedMatch.id,
          winnerId: testTeams[0].id,
          loserId: testTeams[2].id,
        );
      });

      test('getActiveMatches deve retornar partidas ativas', () {
        final activeMatches = matchesProvider.getActiveMatches();
        
        expect(activeMatches, hasLength(2));
        expect(activeMatches.every((m) => !m.isComplete), isTrue);
      });

      test('getCompletedMatches deve retornar partidas finalizadas', () {
        final completedMatches = matchesProvider.getCompletedMatches();
        
        expect(completedMatches, hasLength(1));
        expect(completedMatches.every((m) => m.isComplete), isTrue);
      });

      test('getMatchesByTeam deve filtrar por time', () {
        final teamMatches = matchesProvider.getMatchesByTeam(testTeams[0].id);
        
        expect(teamMatches, hasLength(2));
        expect(
          teamMatches.every((m) => 
            m.teamAId == testTeams[0].id || m.teamBId == testTeams[0].id),
          isTrue,
        );
      });

      test('getMatchesByTeams deve filtrar por par de times', () {
        final pairMatches = matchesProvider.getMatchesByTeams(
          testTeams[0].id,
          testTeams[1].id,
        );
        
        expect(pairMatches, hasLength(1));
        expect(
          pairMatches.every((m) => 
            (m.teamAId == testTeams[0].id && m.teamBId == testTeams[1].id) ||
            (m.teamAId == testTeams[1].id && m.teamBId == testTeams[0].id)),
          isTrue,
        );
      });

      test('getRecentMatches deve retornar partidas recentes', () {
        final recentMatches = matchesProvider.getRecentMatches(limit: 2);
        
        expect(recentMatches, hasLength(2));
      });

      test('getMatchesByDateRange deve filtrar por período', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));
        
        final matches = matchesProvider.getMatchesByDateRange(
          start: yesterday,
          end: tomorrow,
        );
        
        expect(matches, hasLength(3)); // Todas as partidas de hoje
      });
    });

    group('Estatísticas', () {
      setUp(() async {
        // Criar várias partidas com resultados diferentes
        for (int i = 0; i < 5; i++) {
          final match = await matchesProvider.createMatch(
            teamAId: testTeams[0].id,
            teamBId: testTeams[1].id,
          );
          
          await matchesProvider.setTeamAScore(match.id, 10);
          await matchesProvider.setTeamBScore(match.id, i * 2);
          
          await matchesProvider.completeMatch(
            match.id,
            winnerId: testTeams[0].id,
            loserId: testTeams[1].id,
          );
        }
        
        // Criar uma partida com empate
        final tieMatch = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        await matchesProvider.setTeamAScore(tieMatch.id, 5);
        await matchesProvider.setTeamBScore(tieMatch.id, 5);
        await matchesProvider.completeMatch(tieMatch.id);
      });

      test('getTeamWins deve contar vitórias do time', () {
        final wins = matchesProvider.getTeamWins(testTeams[0].id);
        expect(wins, equals(5));
      });

      test('getTeamLosses deve contar derrotas do time', () {
        final losses = matchesProvider.getTeamLosses(testTeams[1].id);
        expect(losses, equals(5));
      });

      test('getTeamTies deve contar empates do time', () {
        final ties = matchesProvider.getTeamTies(testTeams[0].id);
        expect(ties, equals(1));
      });

      test('getTeamWinRate deve calcular taxa de vitórias', () {
        final winRate = matchesProvider.getTeamWinRate(testTeams[0].id);
        expect(winRate, closeTo(5/6, 0.01)); // 5 vitórias em 6 partidas
      });

      test('getTeamStats deve retornar estatísticas completas', () {
        final stats = matchesProvider.getTeamStats(testTeams[0].id);
        
        expect(stats['wins'], equals(5));
        expect(stats['losses'], equals(0));
        expect(stats['ties'], equals(1));
        expect(stats['totalMatches'], equals(6));
        expect(stats['winRate'], closeTo(5/6, 0.01));
      });

      test('getAverageMatchDuration deve calcular duração média', () {
        final avgDuration = matchesProvider.getAverageMatchDuration();
        
        expect(avgDuration, isA<Duration>());
        expect(avgDuration.inSeconds, greaterThan(0));
      });

      test('getTotalMatchesPlayed deve contar total de partidas', () {
        final total = matchesProvider.getTotalMatchesPlayed();
        expect(total, equals(6));
      });
    });

    group('Busca e Ordenação', () {
      setUp(() async {
        // Criar partidas com diferentes características
        final match1 = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        await matchesProvider.setTeamAScore(match1.id, 15);
        await matchesProvider.setTeamBScore(match1.id, 10);
        
        final match2 = await matchesProvider.createMatch(
          teamAId: testTeams[2].id,
          teamBId: testTeams[3].id,
        );
        await matchesProvider.setTeamAScore(match2.id, 5);
        await matchesProvider.setTeamBScore(match2.id, 20);
        
        await Future.delayed(const Duration(milliseconds: 50));
        
        final match3 = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[3].id,
        );
        await matchesProvider.setTeamAScore(match3.id, 8);
        await matchesProvider.setTeamBScore(match3.id, 8);
      });

      test('searchMatches deve buscar por critérios', () {
        final highScoreMatches = matchesProvider.searchMatches(
          minScore: 15,
        );
        
        expect(highScoreMatches, hasLength(2));
      });

      test('sortMatchesByDate deve ordenar por data', () {
        final sortedMatches = matchesProvider.sortMatchesByDate(
          ascending: false,
        );
        
        expect(sortedMatches, hasLength(3));
        // Verificar se está ordenado (mais recente primeiro)
        for (int i = 0; i < sortedMatches.length - 1; i++) {
          expect(
            sortedMatches[i].startTime.isAfter(sortedMatches[i + 1].startTime) ||
            sortedMatches[i].startTime.isAtSameMomentAs(sortedMatches[i + 1].startTime),
            isTrue,
          );
        }
      });

      test('sortMatchesByScore deve ordenar por pontuação total', () {
        final sortedMatches = matchesProvider.sortMatchesByScore(
          ascending: false,
        );
        
        expect(sortedMatches, hasLength(3));
        // Verificar se está ordenado (maior pontuação primeiro)
        for (int i = 0; i < sortedMatches.length - 1; i++) {
          final currentTotal = sortedMatches[i].teamAScore + sortedMatches[i].teamBScore;
          final nextTotal = sortedMatches[i + 1].teamAScore + sortedMatches[i + 1].teamBScore;
          expect(currentTotal, greaterThanOrEqualTo(nextTotal));
        }
      });
    });

    group('Importação e Exportação', () {
      setUp(() async {
        // Criar algumas partidas para exportar
        for (int i = 0; i < 3; i++) {
          final match = await matchesProvider.createMatch(
            teamAId: testTeams[i % 2].id,
            teamBId: testTeams[(i + 1) % 2].id,
          );
          
          await matchesProvider.setTeamAScore(match.id, i + 1);
          await matchesProvider.setTeamBScore(match.id, i);
          
          if (i < 2) {
            await matchesProvider.completeMatch(
              match.id,
              winnerId: testTeams[i % 2].id,
              loserId: testTeams[(i + 1) % 2].id,
            );
          }
        }
      });

      test('exportMatches deve exportar dados das partidas', () {
        final exportData = matchesProvider.exportMatches();
        
        expect(exportData, isA<List<Map<String, dynamic>>>());
        expect(exportData, hasLength(3));
        
        for (final matchData in exportData) {
          expect(matchData, containsPair('id', isA<String>()));
          expect(matchData, containsPair('teamAId', isA<String>()));
          expect(matchData, containsPair('teamBId', isA<String>()));
          expect(matchData, containsPair('teamAScore', isA<int>()));
          expect(matchData, containsPair('teamBScore', isA<int>()));
        }
      });

      test('importMatches deve importar dados das partidas', () async {
        final exportData = matchesProvider.exportMatches();
        
        // Limpar partidas atuais
        await matchesProvider.clearAllMatches();
        expect(matchesProvider.matches, isEmpty);
        
        // Importar dados
        await matchesProvider.importMatches(exportData);
        
        expect(matchesProvider.matches, hasLength(3));
      });

      test('clearAllMatches deve remover todas as partidas', () async {
        expect(matchesProvider.matches, isNotEmpty);
        
        await matchesProvider.clearAllMatches();
        
        expect(matchesProvider.matches, isEmpty);
        expect(matchesProvider.matchCount, equals(0));
      });
    });

    group('Persistência', () {
      test('deve salvar partidas automaticamente', () async {
        await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        // Criar novo provider e verificar se carregou
        final newProvider = MatchesNotifier();
        await newProvider.loadMatches();
        
        expect(newProvider.matches, isNotEmpty);
      });

      test('deve manter estado após operações', () async {
        final match = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        await matchesProvider.setTeamAScore(match.id, 7);
        await matchesProvider.completeMatch(match.id);
        
        // Simular reinicialização
        final newProvider = MatchesNotifier();
        await newProvider.loadMatches();
        
        final loadedMatch = newProvider.getMatch(match.id);
        expect(loadedMatch, isNotNull);
        expect(loadedMatch!.teamAScore, equals(7));
        expect(loadedMatch.isComplete, isTrue);
      });
    });

    group('Tratamento de Erros', () {
      test('deve lidar com partida inexistente', () {
        expect(
          () => matchesProvider.incrementTeamAScore('inexistente'),
          throwsA(isA<ArgumentError>()),
        );
        
        expect(
          () => matchesProvider.completeMatch('inexistente'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('deve validar pontuações negativas', () async {
        final match = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        expect(
          () => matchesProvider.setTeamAScore(match.id, -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('deve validar operações em partida finalizada', () async {
        final match = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        await matchesProvider.completeMatch(match.id);
        
        expect(
          () => matchesProvider.incrementTeamAScore(match.id),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Notificações', () {
      test('deve notificar listeners em operações', () async {
        int notificationCount = 0;
        matchesProvider.addListener(() {
          notificationCount++;
        });
        
        final match = await matchesProvider.createMatch(
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        await matchesProvider.incrementTeamAScore(match.id);
        await matchesProvider.completeMatch(match.id);
        
        expect(notificationCount, greaterThan(0));
      });
    });
  });
}