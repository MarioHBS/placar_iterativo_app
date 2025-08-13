import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import '../test_utils.dart';

void main() {
  group('TournamentProvider Tests', () {
    late TournamentNotifier tournamentProvider;
    late List<Team> testTeams;
    late GameConfig gameConfig;

    setUp(() async {
      await TestUtils.initializeHiveForTesting();
      tournamentProvider = TournamentNotifier();
      
      testTeams = [
        TestUtils.createTestTeam(id: 'team1', name: 'Team 1'),
        TestUtils.createTestTeam(id: 'team2', name: 'Team 2'),
        TestUtils.createTestTeam(id: 'team3', name: 'Team 3'),
        TestUtils.createTestTeam(id: 'team4', name: 'Team 4'),
      ];
      
      gameConfig = TestUtils.createTestGameConfig(
        endCondition: EndCondition.score,
        maxScore: 10,
        tournamentEndCondition: TournamentEndCondition.firstToWins,
        firstToWins: 3,
      );
      
      // Aguardar inicialização
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Inicialização', () {
      test('deve inicializar com estado correto', () {
        expect(tournamentProvider.tournaments, isEmpty);
        expect(tournamentProvider.currentTournament, isNull);
        expect(tournamentProvider.activeTournaments, isEmpty);
        expect(tournamentProvider.completedTournaments, isEmpty);
      });

      test('deve carregar torneios existentes', () async {
        // Criar e salvar um torneio
        final tournament = TestUtils.createTestTournament(
          id: 'test_tournament',
          name: 'Test Tournament',
          config: gameConfig,
        );
        
        await tournamentProvider.createTournament(
          name: tournament.name,
          config: tournament.config,
          teams: testTeams,
        );
        
        // Criar novo provider e verificar carregamento
        final newProvider = TournamentNotifier();
        await newProvider.loadTournaments();
        
        expect(newProvider.tournaments, isNotEmpty);
      });
    });

    group('Criação de Torneio', () {
      test('createTournament deve criar novo torneio', () async {
        final tournament = await tournamentProvider.createTournament(
          name: 'Novo Torneio',
          config: gameConfig,
          teams: testTeams,
        );
        
        expect(tournament, isNotNull);
        expect(tournament.name, equals('Novo Torneio'));
        expect(tournament.config, equals(gameConfig));
        expect(tournament.teamIds, hasLength(testTeams.length));
        expect(tournament.isActive, isTrue);
        expect(tournamentProvider.tournaments, contains(tournament));
      });

      test('createTournament deve definir como torneio atual', () async {
        final tournament = await tournamentProvider.createTournament(
          name: 'Torneio Atual',
          config: gameConfig,
          teams: testTeams,
        );
        
        expect(tournamentProvider.currentTournament, equals(tournament));
      });

      test('createTournament deve notificar listeners', () async {
        bool notified = false;
        tournamentProvider.addListener(() {
          notified = true;
        });
        
        await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
        
        expect(notified, isTrue);
      });

      test('createTournament deve validar parâmetros', () async {
        // Nome vazio
        expect(
          () => tournamentProvider.createTournament(
            name: '',
            config: gameConfig,
            teams: testTeams,
          ),
          throwsA(isA<ArgumentError>()),
        );
        
        // Lista de times vazia
        expect(
          () => tournamentProvider.createTournament(
            name: 'Torneio Válido',
            config: gameConfig,
            teams: [],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Gerenciamento de Torneio Atual', () {
      late Tournament tournament;
      
      setUp(() async {
        tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
      });

      test('setCurrentTournament deve definir torneio atual', () {
        final newTournament = TestUtils.createTestTournament(
          id: 'new_tournament',
          name: 'Novo Torneio',
          config: gameConfig,
        );
        
        tournamentProvider.setCurrentTournament(newTournament);
        
        expect(tournamentProvider.currentTournament, equals(newTournament));
      });

      test('clearCurrentTournament deve limpar torneio atual', () {
        tournamentProvider.clearCurrentTournament();
        
        expect(tournamentProvider.currentTournament, isNull);
      });

      test('hasCurrentTournament deve verificar existência', () {
        expect(tournamentProvider.hasCurrentTournament(), isTrue);
        
        tournamentProvider.clearCurrentTournament();
        expect(tournamentProvider.hasCurrentTournament(), isFalse);
      });
    });

    group('Gerenciamento de Times', () {
      late Tournament tournament;
      
      setUp(() async {
        tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams.take(2).toList(),
        );
      });

      test('addTeamToTournament deve adicionar time', () async {
        final newTeam = TestUtils.createTestTeam(id: 'new_team', name: 'New Team');
        
        await tournamentProvider.addTeamToTournament(
          tournamentId: tournament.id,
          team: newTeam,
        );
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.hasTeam(newTeam.id), isTrue);
      });

      test('removeTeamFromTournament deve remover time', () async {
        final teamToRemove = testTeams.first;
        
        await tournamentProvider.removeTeamFromTournament(
          tournamentId: tournament.id,
          teamId: teamToRemove.id,
        );
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.hasTeam(teamToRemove.id), isFalse);
      });

      test('getTeamsInTournament deve retornar times do torneio', () {
        final teams = tournamentProvider.getTeamsInTournament(tournament.id);
        
        expect(teams, hasLength(2));
        expect(teams.map((t) => t.id), containsAll(testTeams.take(2).map((t) => t.id)));
      });
    });

    group('Gerenciamento de Partidas', () {
      late Tournament tournament;
      
      setUp(() async {
        tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
      });

      test('startMatch deve iniciar nova partida', () async {
        final match = await tournamentProvider.startMatch(
          tournamentId: tournament.id,
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        expect(match, isNotNull);
        expect(match.teamAId, equals(testTeams[0].id));
        expect(match.teamBId, equals(testTeams[1].id));
        expect(match.isComplete, isFalse);
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.hasCurrentMatch(), isTrue);
      });

      test('completeMatch deve finalizar partida', () async {
        final match = await tournamentProvider.startMatch(
          tournamentId: tournament.id,
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        match.teamAScore = 10;
        match.teamBScore = 5;
        
        await tournamentProvider.completeMatch(
          tournamentId: tournament.id,
          match: match,
        );
        
        expect(match.isComplete, isTrue);
        expect(match.winnerId, equals(testTeams[0].id));
        expect(match.loserId, equals(testTeams[1].id));
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.hasCurrentMatch(), isFalse);
      });

      test('getMatchesInTournament deve retornar partidas', () async {
        await tournamentProvider.startMatch(
          tournamentId: tournament.id,
          teamAId: testTeams[0].id,
          teamBId: testTeams[1].id,
        );
        
        final matches = tournamentProvider.getMatchesInTournament(tournament.id);
        
        expect(matches, hasLength(1));
        expect(matches.first.teamAId, equals(testTeams[0].id));
        expect(matches.first.teamBId, equals(testTeams[1].id));
      });
    });

    group('Fila de Times', () {
      late Tournament tournament;
      
      setUp(() async {
        tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
      });

      test('addToQueue deve adicionar time à fila', () async {
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[0].id,
        );
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.isInQueue(testTeams[0].id), isTrue);
      });

      test('removeFromQueue deve remover time da fila', () async {
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[0].id,
        );
        
        await tournamentProvider.removeFromQueue(
          tournamentId: tournament.id,
          teamId: testTeams[0].id,
        );
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.isInQueue(testTeams[0].id), isFalse);
      });

      test('getNextInQueue deve retornar próximo da fila', () async {
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[0].id,
        );
        
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[1].id,
        );
        
        final nextTeam = tournamentProvider.getNextInQueue(tournament.id);
        expect(nextTeam, equals(testTeams[0].id));
      });

      test('getQueuePosition deve retornar posição na fila', () async {
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[0].id,
        );
        
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[1].id,
        );
        
        final position = tournamentProvider.getQueuePosition(
          tournament.id,
          testTeams[1].id,
        );
        
        expect(position, equals(1)); // Segunda posição (índice 1)
      });
    });

    group('Estatísticas e Classificação', () {
      late Tournament tournament;
      
      setUp(() async {
        tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
        
        // Simular algumas partidas
        for (int i = 0; i < 3; i++) {
          final match = await tournamentProvider.startMatch(
            tournamentId: tournament.id,
            teamAId: testTeams[0].id,
            teamBId: testTeams[1].id,
          );
          
          match.teamAScore = 10;
          match.teamBScore = 5;
          
          await tournamentProvider.completeMatch(
            tournamentId: tournament.id,
            match: match,
          );
        }
      });

      test('getLeaderboard deve retornar classificação', () {
        final leaderboard = tournamentProvider.getLeaderboard(tournament.id);
        
        expect(leaderboard, isNotEmpty);
        expect(leaderboard.first['teamId'], equals(testTeams[0].id));
        expect(leaderboard.first['wins'], equals(3));
      });

      test('getTeamStats deve retornar estatísticas do time', () {
        final stats = tournamentProvider.getTeamStats(
          tournament.id,
          testTeams[0].id,
        );
        
        expect(stats['wins'], equals(3));
        expect(stats['losses'], equals(0));
        expect(stats['winRate'], equals(1.0));
      });

      test('getTournamentProgress deve calcular progresso', () {
        final progress = tournamentProvider.getTournamentProgress(tournament.id);
        
        expect(progress, isA<double>());
        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      });
    });

    group('Filtros e Consultas', () {
      setUp(() async {
        // Criar torneios ativos
        await tournamentProvider.createTournament(
          name: 'Torneio Ativo 1',
          config: gameConfig,
          teams: testTeams.take(2).toList(),
        );
        
        await tournamentProvider.createTournament(
          name: 'Torneio Ativo 2',
          config: gameConfig,
          teams: testTeams.skip(2).take(2).toList(),
        );
        
        // Criar e completar um torneio
        final completedTournament = await tournamentProvider.createTournament(
          name: 'Torneio Completo',
          config: gameConfig,
          teams: testTeams.take(2).toList(),
        );
        
        await tournamentProvider.completeTournament(completedTournament.id);
      });

      test('getActiveTournaments deve retornar torneios ativos', () {
        final activeTournaments = tournamentProvider.getActiveTournaments();
        
        expect(activeTournaments, hasLength(2));
        expect(activeTournaments.every((t) => t.isActive), isTrue);
      });

      test('getCompletedTournaments deve retornar torneios completos', () {
        final completedTournaments = tournamentProvider.getCompletedTournaments();
        
        expect(completedTournaments, hasLength(1));
        expect(completedTournaments.every((t) => !t.isActive), isTrue);
      });

      test('getRecentTournaments deve retornar torneios recentes', () {
        final recentTournaments = tournamentProvider.getRecentTournaments(limit: 2);
        
        expect(recentTournaments, hasLength(2));
      });

      test('searchTournaments deve buscar por nome', () {
        final results = tournamentProvider.searchTournaments('Ativo');
        
        expect(results, hasLength(2));
        expect(results.every((t) => t.name.contains('Ativo')), isTrue);
      });

      test('getTournamentsByTeam deve filtrar por time', () {
        final tournaments = tournamentProvider.getTournamentsByTeam(testTeams[0].id);
        
        expect(tournaments, isNotEmpty);
        expect(tournaments.every((t) => t.hasTeam(testTeams[0].id)), isTrue);
      });
    });

    group('Finalização de Torneio', () {
      late Tournament tournament;
      
      setUp(() async {
        tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
      });

      test('completeTournament deve finalizar torneio', () async {
        await tournamentProvider.completeTournament(tournament.id);
        
        final updatedTournament = tournamentProvider.getTournament(tournament.id);
        expect(updatedTournament!.isActive, isFalse);
        expect(updatedTournament.completedAt, isNotNull);
      });

      test('isTournamentComplete deve verificar condições de fim', () {
        // Simular vitórias suficientes para um time
        for (int i = 0; i < 3; i++) {
          final match = TestUtils.createTestMatch(
            teamAId: testTeams[0].id,
            teamBId: testTeams[1].id,
            teamAScore: 10,
            teamBScore: 5,
            isComplete: true,
            winnerId: testTeams[0].id,
          );
          
          tournament.addMatch(match);
          tournament.completeMatch(match, testTeams[0], testTeams[1]);
        }
        
        final isComplete = tournamentProvider.isTournamentComplete(tournament.id);
        expect(isComplete, isTrue);
      });
    });

    group('Persistência', () {
      test('deve salvar torneios automaticamente', () async {
        await tournamentProvider.createTournament(
          name: 'Torneio Persistente',
          config: gameConfig,
          teams: testTeams,
        );
        
        // Criar novo provider e verificar se carregou
        final newProvider = TournamentNotifier();
        await newProvider.loadTournaments();
        
        expect(newProvider.tournaments, isNotEmpty);
        expect(
          newProvider.tournaments.any((t) => t.name == 'Torneio Persistente'),
          isTrue,
        );
      });

      test('deve manter estado após reinicialização', () async {
        final tournament = await tournamentProvider.createTournament(
          name: 'Torneio Estado',
          config: gameConfig,
          teams: testTeams,
        );
        
        await tournamentProvider.addToQueue(
          tournamentId: tournament.id,
          teamId: testTeams[0].id,
        );
        
        // Simular reinicialização
        final newProvider = TournamentNotifier();
        await newProvider.loadTournaments();
        
        final loadedTournament = newProvider.tournaments
            .firstWhere((t) => t.name == 'Torneio Estado');
        
        expect(loadedTournament.isInQueue(testTeams[0].id), isTrue);
      });
    });

    group('Tratamento de Erros', () {
      test('deve lidar com torneio inexistente', () {
        expect(
          () => tournamentProvider.getTournament('inexistente'),
          returnsNormally,
        );
        
        expect(tournamentProvider.getTournament('inexistente'), isNull);
      });

      test('deve validar operações em torneio completo', () async {
        final tournament = await tournamentProvider.createTournament(
          name: 'Torneio Teste',
          config: gameConfig,
          teams: testTeams,
        );
        
        await tournamentProvider.completeTournament(tournament.id);
        
        // Tentar adicionar time a torneio completo
        expect(
          () => tournamentProvider.addTeamToTournament(
            tournamentId: tournament.id,
            team: testTeams[0],
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Notificações', () {
      test('deve notificar listeners em operações', () async {
        int notificationCount = 0;
        tournamentProvider.addListener(() {
          notificationCount++;
        });
        
        await tournamentProvider.createTournament(
          name: 'Torneio Notificação',
          config: gameConfig,
          teams: testTeams,
        );
        
        expect(notificationCount, greaterThan(0));
      });
    });
  });
}