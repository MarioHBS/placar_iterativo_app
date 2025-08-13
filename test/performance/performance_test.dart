import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import 'package:placar_iterativo_app/services/backup_service.dart';
import '../test_utils.dart';

void main() {
  group('Performance Tests', () {
    setUp(() async {
      await TestUtils.initializeHiveForTesting();
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Providers Performance', () {
      group('TeamsProvider Performance', () {
        test('deve criar 1000 times rapidamente', () async {
          final teamsProvider = TeamsNotifier();
          await teamsProvider.initialize();
          
          final stopwatch = Stopwatch()..start();
          
          for (int i = 0; i < 1000; i++) {
            await teamsProvider.createTeam('Team $i');
          }
          
          stopwatch.stop();
          
          // Deve criar 1000 times em menos de 5 segundos
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
          expect(teamsProvider.teams.length, equals(1000));
        });

        test('deve buscar times rapidamente em lista grande', () async {
          final teamsProvider = TeamsNotifier();
          await teamsProvider.initialize();
          
          // Criar muitos times
          for (int i = 0; i < 5000; i++) {
            await teamsProvider.createTeam('Team $i');
          }
          
          final stopwatch = Stopwatch()..start();
          
          // Buscar times
          final results = teamsProvider.searchTeams('Team 2500');
          
          stopwatch.stop();
          
          // Busca deve ser rápida (menos de 100ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(100));
          expect(results, isNotEmpty);
        });

        test('deve filtrar times por cor rapidamente', () async {
          final teamsProvider = TeamsNotifier();
          await teamsProvider.initialize();
          
          // Criar times com cores diferentes
          for (int i = 0; i < 2000; i++) {
            final team = await teamsProvider.createTeam('Team $i');
            await teamsProvider.updateTeam(
              team.id,
              color: i % 2 == 0 ? Colors.blue : Colors.red,
            );
          }
          
          final stopwatch = Stopwatch()..start();
          
          final blueTeams = teamsProvider.getTeamsByColor(Colors.blue);
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(50));
          expect(blueTeams.length, equals(1000));
        });

        test('deve calcular estatísticas rapidamente', () async {
          final teamsProvider = TeamsNotifier();
          await teamsProvider.initialize();
          
          // Criar times com estatísticas
          for (int i = 0; i < 1000; i++) {
            final team = await teamsProvider.createTeam('Team $i');
            for (int j = 0; j < 10; j++) {
              await teamsProvider.addWin(team.id);
              await teamsProvider.addLoss(team.id);
            }
          }
          
          final stopwatch = Stopwatch()..start();
          
          final topTeams = teamsProvider.getTopTeams(100);
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(200));
          expect(topTeams.length, equals(100));
        });
      });

      group('MatchesProvider Performance', () {
        test('deve criar 1000 partidas rapidamente', () async {
          final matchesProvider = MatchesNotifier();
          await matchesProvider.initialize();
          
          final config = TestUtils.createTestGameConfig();
          
          final stopwatch = Stopwatch()..start();
          
          for (int i = 0; i < 1000; i++) {
            await matchesProvider.createMatch(
              'team_a_$i',
              'team_b_$i',
              config,
            );
          }
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(3000));
          expect(matchesProvider.matches.length, equals(1000));
        });

        test('deve filtrar partidas rapidamente', () async {
          final matchesProvider = MatchesNotifier();
          await matchesProvider.initialize();
          
          final config = TestUtils.createTestGameConfig();
          
          // Criar muitas partidas
          for (int i = 0; i < 2000; i++) {
            final match = await matchesProvider.createMatch(
              'team_a',
              'team_b_$i',
              config,
            );
            
            if (i % 2 == 0) {
              await matchesProvider.completeMatch(match.id, 'team_a');
            }
          }
          
          final stopwatch = Stopwatch()..start();
          
          final allMatches = matchesProvider.getAllMatches();
          final completedMatches = allMatches.where((match) => match.isComplete).toList();
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(100));
          expect(completedMatches.length, equals(1000));
        });

        test('deve calcular estatísticas de time rapidamente', () async {
          final matchesProvider = MatchesNotifier();
          await matchesProvider.initialize();
          
          // Criar partidas para um time específico
          for (int i = 0; i < 100; i++) {
            final teamA = TestUtils.createTestTeam(id: 'target_team', name: 'Target Team');
            final teamB = TestUtils.createTestTeam(id: 'opponent_$i', name: 'Opponent $i');
            
            final match = await matchesProvider.createMatchWithTeams(
               teamA: teamA,
               teamB: teamB,
             );
            
            // Simular conclusão da partida
            if (i % 3 == 0) {
              match.teamAScore = 15;
              match.teamBScore = 10;
            } else {
              match.teamAScore = 10;
              match.teamBScore = 15;
            }
            
            await matchesProvider.completeMatch(match.id);
          }
          
          final stopwatch = Stopwatch()..start();
          
          final allMatches = matchesProvider.getAllMatches();
          final targetTeamMatches = allMatches.where((match) => 
            match.teamAId == 'target_team' || match.teamBId == 'target_team'
          ).toList();
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(150));
          expect(targetTeamMatches.length, equals(100));
        });
      });

      group('TournamentProvider Performance', () {
        test('deve criar torneio com muitos times rapidamente', () async {
          final tournamentProvider = TournamentNotifier();
          
          final config = TestUtils.createTestGameConfig();
          final teams = List.generate(100, (i) => 
            TestUtils.createTestTeam(id: 'team_$i', name: 'Team $i')
          );
          
          final stopwatch = Stopwatch()..start();
          
          final tournament = await tournamentProvider.createTournament(
            name: 'Large Tournament',
            config: config,
            teams: teams,
          );
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
          expect(tournament, isNotNull);
        });

        test('deve calcular classificação rapidamente', () async {
          final tournamentProvider = TournamentNotifier();
          
          final config = TestUtils.createTestGameConfig();
          final teams = List.generate(50, (i) => 
            TestUtils.createTestTeam(id: 'team_$i', name: 'Team $i')
          );
          
          final tournament = await tournamentProvider.createTournament(
            name: 'Performance Tournament',
            config: config,
            teams: teams,
          );
          
          final stopwatch = Stopwatch()..start();
          
          // Simular acesso aos dados do torneio
          final retrievedTournament = tournamentProvider.getTournament(tournament.id);
          final activeTournaments = tournamentProvider.getActiveTournaments();
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(200));
          expect(retrievedTournament, isNotNull);
          expect(activeTournaments.isNotEmpty, isTrue);
        });
      });
    });

    group('Services Performance', () {
      group('HiveService Performance', () {
        test('deve salvar muitos times rapidamente', () async {
          await HiveService.init();
          
          final teams = List.generate(1000, (i) => 
            TestUtils.createTestTeam(
              id: 'team_$i',
              name: 'Team $i',
            ),
          );
          
          final stopwatch = Stopwatch()..start();
          
          for (final team in teams) {
            await HiveService.saveTeam(team);
          }
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        });

        test('deve recuperar muitos times rapidamente', () async {
          await HiveService.init();
          
          // Salvar times primeiro
          for (int i = 0; i < 1000; i++) {
            final team = TestUtils.createTestTeam(
              id: 'team_$i',
              name: 'Team $i',
            );
            await HiveService.saveTeam(team);
          }
          
          final stopwatch = Stopwatch()..start();
          
          final teamsBox = Hive.box<Team>('teams');
          final teams = teamsBox.values.toList();
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(500));
          expect(teams.length, equals(1000));
        });

        test('deve limpar dados rapidamente', () async {
          await HiveService.init();
          
          // Adicionar muitos dados
          for (int i = 0; i < 1000; i++) {
            await HiveService.saveTeam(
              TestUtils.createTestTeam(id: 'team_$i', name: 'Team $i'),
            );
            await HiveService.saveMatch(
              TestUtils.createTestMatch(id: 'match_$i'),
            );
          }
          
          final stopwatch = Stopwatch()..start();
          
          await HiveService.clearAllBoxes();
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        });
      });

      group('BackupService Performance', () {
        test('deve criar backup de muitos dados rapidamente', () async {
          // Adicionar muitos dados
          final teamsBox = Hive.box<Team>('teams');
          final matchesBox = Hive.box<Match>('matches');
          
          for (int i = 0; i < 1000; i++) {
            await teamsBox.put(
              'team_$i',
              TestUtils.createTestTeam(id: 'team_$i', name: 'Team $i'),
            );
            await matchesBox.put(
              'match_$i',
              TestUtils.createTestMatch(id: 'match_$i'),
            );
          }
          
          final stopwatch = Stopwatch()..start();
          
          final backup = await BackupService.createBackup();
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(2000));
          expect(backup, isNotNull);
        });

        test('deve restaurar backup rapidamente', () async {
          // Criar backup com dados
          for (int i = 0; i < 500; i++) {
            final teamsBox = Hive.box<Team>('teams');
            await teamsBox.put(
              'team_$i',
              TestUtils.createTestTeam(id: 'team_$i', name: 'Team $i'),
            );
          }
          
          final backup = await BackupService.createBackup();
          
          // Limpar dados
          await TestUtils.clearAllHiveBoxes();
          
          final stopwatch = Stopwatch()..start();
          
          await BackupService.restoreBackup(backup);
          
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(1500));
          
          final teamsBox = Hive.box<Team>('teams');
          expect(teamsBox.length, equals(500));
        });
      });
    });

    group('Memory Performance', () {
      test('deve gerenciar memória eficientemente com muitos dados', () async {
        final teamsProvider = TeamsNotifier();
        await teamsProvider.initialize();
        
        // Criar e remover times repetidamente
        for (int cycle = 0; cycle < 10; cycle++) {
          final teamIds = <String>[];
          
          // Criar 100 times
          for (int i = 0; i < 100; i++) {
            final team = await teamsProvider.createTeam('Temp Team $i');
            teamIds.add(team.id);
          }
          
          // Remover todos os times
          for (final teamId in teamIds) {
            await teamsProvider.deleteTeam(teamId);
          }
          
          expect(teamsProvider.teams.length, equals(0));
        }
        
        // Verificar se não há vazamentos de memória
        expect(teamsProvider.teams.length, equals(0));
      });

      test('deve lidar com listeners eficientemente', () async {
        final teamsProvider = TeamsNotifier();
        await teamsProvider.initialize();
        
        final listeners = <VoidCallback>[];
        
        // Adicionar muitos listeners
        for (int i = 0; i < 100; i++) {
          final listener = () {};
          listeners.add(listener);
          teamsProvider.addListener(listener);
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Operação que notifica listeners
        await teamsProvider.createTeam('Test Team');
        
        stopwatch.stop();
        
        // Deve notificar rapidamente mesmo com muitos listeners
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        
        // Remover listeners
        for (final listener in listeners) {
          teamsProvider.removeListener(listener);
        }
      });
    });

    group('Concurrent Operations', () {
      test('deve lidar com operações concorrentes', () async {
        final teamsProvider = TeamsNotifier();
        await teamsProvider.initialize();
        
        final futures = <Future>[];
        
        final stopwatch = Stopwatch()..start();
        
        // Executar operações concorrentes
        for (int i = 0; i < 50; i++) {
          futures.add(teamsProvider.createTeam('Concurrent Team $i'));
        }
        
        await Future.wait(futures);
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        expect(teamsProvider.teams.length, equals(50));
      });

      test('deve manter consistência com operações concorrentes', () async {
        final matchesProvider = MatchesNotifier();
        await matchesProvider.initialize();
        
        final config = TestUtils.createTestGameConfig();
        final match = await matchesProvider.createMatch(
          'team_a',
          'team_b',
          config,
        );
        
        final futures = <Future>[];
        
        // Incrementar pontuação concorrentemente
        for (int i = 0; i < 20; i++) {
          futures.add(matchesProvider.incrementTeamAScore(match.id));
          futures.add(matchesProvider.incrementTeamBScore(match.id));
        }
        
        await Future.wait(futures);
        
        final updatedMatch = matchesProvider.getMatch(match.id);
        expect(updatedMatch!.teamAScore, equals(20));
        expect(updatedMatch.teamBScore, equals(20));
      });
    });

    group('Large Dataset Performance', () {
      test('deve lidar com dataset muito grande', () async {
        final teamsProvider = TeamsNotifier();
        final matchesProvider = MatchesNotifier();
        
        await teamsProvider.initialize();
        await matchesProvider.initialize();
        
        final stopwatch = Stopwatch()..start();
        
        // Criar 10.000 times
        for (int i = 0; i < 10000; i++) {
          await teamsProvider.createTeam('Team $i');
          
          if (i % 1000 == 0) {
            print('Created ${i + 1} teams');
          }
        }
        
        stopwatch.stop();
        print('Created 10,000 teams in ${stopwatch.elapsedMilliseconds}ms');
        
        // Deve criar em tempo razoável (menos de 30 segundos)
        expect(stopwatch.elapsedMilliseconds, lessThan(30000));
        expect(teamsProvider.teams.length, equals(10000));
        
        // Testar busca em dataset grande
        final searchStopwatch = Stopwatch()..start();
        final results = teamsProvider.searchTeams('Team 5000');
        searchStopwatch.stop();
        
        expect(searchStopwatch.elapsedMilliseconds, lessThan(200));
        expect(results, isNotEmpty);
      });
    });

    group('Stress Tests', () {
      test('deve sobreviver a operações intensivas', () async {
        final teamsProvider = TeamsNotifier();
        await teamsProvider.initialize();
        
        // Operações intensivas por 30 segundos
        final endTime = DateTime.now().add(const Duration(seconds: 30));
        int operationCount = 0;
        
        while (DateTime.now().isBefore(endTime)) {
          final team = await teamsProvider.createTeam('Stress Team $operationCount');
          await teamsProvider.updateTeam(team.id, name: 'Updated $operationCount');
          await teamsProvider.addWin(team.id);
          await teamsProvider.addLoss(team.id);
          
          if (operationCount % 2 == 0) {
            await teamsProvider.deleteTeam(team.id);
          }
          
          operationCount++;
        }
        
        print('Performed $operationCount operations in 30 seconds');
        
        // Deve ter realizado muitas operações
        expect(operationCount, greaterThan(100));
        
        // Provider deve ainda estar funcional
        expect(teamsProvider.teams, isNotNull);
      });
    });
  });
}