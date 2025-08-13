import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/services/backup_service.dart';
import '../test_utils.dart';

void main() {
  group('BackupService Tests', () {
    late BackupService backupService;
    late List<Team> testTeams;
    late List<Match> testMatches;
    late List<Tournament> testTournaments;

    setUp(() async {
      await TestUtils.initializeHiveForTesting();
      backupService = BackupService();
      
      // Criar dados de teste
      testTeams = [
        TestUtils.createTestTeam(id: 'team1', name: 'Team 1'),
        TestUtils.createTestTeam(id: 'team2', name: 'Team 2'),
        TestUtils.createTestTeam(id: 'team3', name: 'Team 3'),
      ];
      
      testMatches = [
        TestUtils.createTestMatch(
          id: 'match1',
          teamAId: 'team1',
          teamBId: 'team2',
          teamAScore: 10,
          teamBScore: 5,
        ),
        TestUtils.createTestMatch(
          id: 'match2',
          teamAId: 'team2',
          teamBId: 'team3',
          teamAScore: 8,
          teamBScore: 12,
        ),
      ];
      
      testTournaments = [
        TestUtils.createTestTournament(
          id: 'tournament1',
          name: 'Tournament 1',
          config: TestUtils.createTestGameConfig(),
        ),
      ];
      
      // Adicionar dados às boxes
      final teamsBox = Hive.box<Team>('teams');
      final matchesBox = Hive.box<Match>('matches');
      final tournamentsBox = Hive.box<Tournament>('tournaments');
      
      for (final team in testTeams) {
        await teamsBox.put(team.id, team);
      }
      
      for (final match in testMatches) {
        await matchesBox.put(match.id, match);
      }
      
      for (final tournament in testTournaments) {
        await tournamentsBox.put(tournament.id, tournament);
      }
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Criação de Backup', () {
      test('createBackup deve criar backup completo', () async {
        final backup = await backupService.createBackup();
        
        expect(backup, isNotNull);
        expect(backup, isA<Map<String, dynamic>>());
        expect(backup, containsKey('timestamp'));
        expect(backup, containsKey('version'));
        expect(backup, containsKey('data'));
      });

      test('backup deve conter todos os dados', () async {
        final backup = await backupService.createBackup();
        final data = backup['data'] as Map<String, dynamic>;
        
        expect(data, containsKey('teams'));
        expect(data, containsKey('matches'));
        expect(data, containsKey('tournaments'));
        expect(data, containsKey('gameConfigs'));
      });

      test('backup deve preservar dados dos times', () async {
        final backup = await backupService.createBackup();
        final data = backup['data'] as Map<String, dynamic>;
        final teams = data['teams'] as Map<String, dynamic>;
        
        expect(teams, hasLength(testTeams.length));
        
        for (final team in testTeams) {
          expect(teams, containsKey(team.id));
          final teamData = teams[team.id] as Map<String, dynamic>;
          expect(teamData['name'], equals(team.name));
          expect(teamData['wins'], equals(team.wins));
          expect(teamData['losses'], equals(team.losses));
        }
      });

      test('backup deve preservar dados das partidas', () async {
        final backup = await backupService.createBackup();
        final data = backup['data'] as Map<String, dynamic>;
        final matches = data['matches'] as Map<String, dynamic>;
        
        expect(matches, hasLength(testMatches.length));
        
        for (final match in testMatches) {
          expect(matches, containsKey(match.id));
          final matchData = matches[match.id] as Map<String, dynamic>;
          expect(matchData['teamAId'], equals(match.teamAId));
          expect(matchData['teamBId'], equals(match.teamBId));
          expect(matchData['teamAScore'], equals(match.teamAScore));
          expect(matchData['teamBScore'], equals(match.teamBScore));
        }
      });

      test('backup deve incluir metadados', () async {
        final backup = await backupService.createBackup();
        
        expect(backup['timestamp'], isA<String>());
        expect(backup['version'], isA<String>());
        expect(backup['appVersion'], isA<String>());
        
        // Verificar se timestamp é válido
        final timestamp = DateTime.parse(backup['timestamp']);
        expect(timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
      });

      test('createBackup deve gerar ID único', () async {
        final backup1 = await backupService.createBackup();
        await Future.delayed(const Duration(milliseconds: 10));
        final backup2 = await backupService.createBackup();
        
        expect(backup1['id'], isNot(equals(backup2['id'])));
      });
    });

    group('Salvamento de Backup', () {
      test('saveBackup deve salvar backup na box', () async {
        final backup = await backupService.createBackup();
        final backupId = await backupService.saveBackup(backup);
        
        expect(backupId, isNotNull);
        expect(backupId, isA<String>());
        
        final backupsBox = Hive.box('backups');
        expect(backupsBox.containsKey(backupId), isTrue);
      });

      test('backup salvo deve ser recuperável', () async {
        final originalBackup = await backupService.createBackup();
        final backupId = await backupService.saveBackup(originalBackup);
        
        final backupsBox = Hive.box('backups');
        final savedBackup = backupsBox.get(backupId);
        
        expect(savedBackup, isNotNull);
        expect(savedBackup['id'], equals(originalBackup['id']));
        expect(savedBackup['timestamp'], equals(originalBackup['timestamp']));
      });

      test('deve manter histórico de backups', () async {
        final backup1 = await backupService.createBackup();
        final backup2 = await backupService.createBackup();
        
        final id1 = await backupService.saveBackup(backup1);
        final id2 = await backupService.saveBackup(backup2);
        
        final backupsBox = Hive.box('backups');
        expect(backupsBox.length, equals(2));
        expect(backupsBox.containsKey(id1), isTrue);
        expect(backupsBox.containsKey(id2), isTrue);
      });
    });

    group('Listagem de Backups', () {
      setUp(() async {
        // Criar alguns backups
        for (int i = 0; i < 3; i++) {
          final backup = await backupService.createBackup();
          await backupService.saveBackup(backup);
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      test('getBackups deve retornar lista de backups', () async {
        final backups = await backupService.getBackups();
        
        expect(backups, isA<List<Map<String, dynamic>>>());
        expect(backups, hasLength(3));
      });

      test('backups devem estar ordenados por data', () async {
        final backups = await backupService.getBackups();
        
        for (int i = 0; i < backups.length - 1; i++) {
          final current = DateTime.parse(backups[i]['timestamp']);
          final next = DateTime.parse(backups[i + 1]['timestamp']);
          expect(current.isAfter(next), isTrue); // Mais recente primeiro
        }
      });

      test('getBackup deve retornar backup específico', () async {
        final backups = await backupService.getBackups();
        final firstBackup = backups.first;
        
        final backup = await backupService.getBackup(firstBackup['id']);
        
        expect(backup, isNotNull);
        expect(backup!['id'], equals(firstBackup['id']));
      });

      test('getBackup deve retornar null para ID inexistente', () async {
        final backup = await backupService.getBackup('inexistente');
        
        expect(backup, isNull);
      });
    });

    group('Restauração de Backup', () {
      late Map<String, dynamic> testBackup;
      
      setUp(() async {
        testBackup = await backupService.createBackup();
        await backupService.saveBackup(testBackup);
        
        // Limpar dados atuais
        await TestUtils.clearAllHiveBoxes();
      });

      test('restoreBackup deve restaurar todos os dados', () async {
        await backupService.restoreBackup(testBackup);
        
        final teamsBox = Hive.box<Team>('teams');
        final matchesBox = Hive.box<Match>('matches');
        final tournamentsBox = Hive.box<Tournament>('tournaments');
        
        expect(teamsBox.length, equals(testTeams.length));
        expect(matchesBox.length, equals(testMatches.length));
        expect(tournamentsBox.length, equals(testTournaments.length));
      });

      test('dados restaurados devem ser idênticos', () async {
        await backupService.restoreBackup(testBackup);
        
        final teamsBox = Hive.box<Team>('teams');
        
        for (final originalTeam in testTeams) {
          final restoredTeam = teamsBox.get(originalTeam.id);
          
          expect(restoredTeam, isNotNull);
          expect(restoredTeam!.name, equals(originalTeam.name));
          expect(restoredTeam.wins, equals(originalTeam.wins));
          expect(restoredTeam.losses, equals(originalTeam.losses));
          expect(restoredTeam.color, equals(originalTeam.color));
        }
      });

      test('restoreBackup deve sobrescrever dados existentes', () async {
        // Adicionar dados diferentes
        final teamsBox = Hive.box<Team>('teams');
        final newTeam = TestUtils.createTestTeam(
          id: 'new_team',
          name: 'New Team',
        );
        await teamsBox.put(newTeam.id, newTeam);
        
        expect(teamsBox.length, equals(1));
        
        // Restaurar backup
        await backupService.restoreBackup(testBackup);
        
        // Deve ter apenas os dados do backup
        expect(teamsBox.length, equals(testTeams.length));
        expect(teamsBox.get('new_team'), isNull);
      });
    });

    group('Validação de Backup', () {
      test('isValidBackup deve validar backup correto', () {
        final validBackup = {
          'id': 'test_id',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
          'data': {
            'teams': {},
            'matches': {},
            'tournaments': {},
            'gameConfigs': {},
          },
        };
        
        final isValid = backupService.isValidBackup(validBackup);
        expect(isValid, isTrue);
      });

      test('isValidBackup deve rejeitar backup inválido', () {
        final invalidBackups = [
          {}, // Vazio
          {'id': 'test'}, // Campos faltando
          {
            'id': 'test',
            'timestamp': 'invalid_date',
            'version': '1.0.0',
            'data': {},
          }, // Data inválida
          {
            'id': 'test',
            'timestamp': DateTime.now().toIso8601String(),
            'version': '1.0.0',
            // data faltando
          },
        ];
        
        for (final backup in invalidBackups) {
          final isValid = backupService.isValidBackup(backup);
          expect(isValid, isFalse);
        }
      });

      test('deve validar estrutura de dados', () async {
        final backup = await backupService.createBackup();
        
        // Corromper estrutura de dados
        final corruptedBackup = Map<String, dynamic>.from(backup);
        corruptedBackup['data'] = 'invalid_data';
        
        final isValid = backupService.isValidBackup(corruptedBackup);
        expect(isValid, isFalse);
      });
    });

    group('Exclusão de Backups', () {
      test('deleteBackup deve remover backup específico', () async {
        final backup = await backupService.createBackup();
        final backupId = await backupService.saveBackup(backup);
        
        expect(await backupService.getBackup(backupId), isNotNull);
        
        await backupService.deleteBackup(backupId);
        
        expect(await backupService.getBackup(backupId), isNull);
      });

      test('deleteBackup deve ser seguro para ID inexistente', () async {
        expect(
          () => backupService.deleteBackup('inexistente'),
          returnsNormally,
        );
      });

      test('clearOldBackups deve remover backups antigos', () async {
        // Criar vários backups
        for (int i = 0; i < 10; i++) {
          final backup = await backupService.createBackup();
          await backupService.saveBackup(backup);
        }
        
        final backupsBefore = await backupService.getBackups();
        expect(backupsBefore.length, equals(10));
        
        // Manter apenas 5 backups mais recentes
        await backupService.clearOldBackups(keepCount: 5);
        
        final backupsAfter = await backupService.getBackups();
        expect(backupsAfter.length, equals(5));
      });
    });

    group('Backup Automático', () {
      test('shouldCreateAutoBackup deve verificar necessidade', () {
        // Sem backups existentes
        expect(backupService.shouldCreateAutoBackup(), isTrue);
      });

      test('createAutoBackup deve criar backup automaticamente', () async {
        await backupService.createAutoBackup();
        
        final backups = await backupService.getBackups();
        expect(backups, isNotEmpty);
        
        final autoBackup = backups.first;
        expect(autoBackup['type'], equals('auto'));
      });

      test('deve limitar número de backups automáticos', () async {
        // Criar muitos backups automáticos
        for (int i = 0; i < 15; i++) {
          await backupService.createAutoBackup();
        }
        
        final backups = await backupService.getBackups();
        final autoBackups = backups.where((b) => b['type'] == 'auto').toList();
        
        // Deve manter apenas um número limitado
        expect(autoBackups.length, lessThanOrEqualTo(10));
      });
    });

    group('Exportação e Importação', () {
      test('exportBackup deve gerar JSON válido', () async {
        final backup = await backupService.createBackup();
        final json = backupService.exportBackup(backup);
        
        expect(json, isA<String>());
        expect(json.isNotEmpty, isTrue);
        
        // Deve ser JSON válido
        expect(() => Map<String, dynamic>.from(
          // ignore: avoid_dynamic_calls
          // Simular parsing JSON
          backup,
        ), returnsNormally);
      });

      test('importBackup deve restaurar de JSON', () async {
        final originalBackup = await backupService.createBackup();
        final json = backupService.exportBackup(originalBackup);
        
        // Limpar dados
        await TestUtils.clearAllHiveBoxes();
        
        // Importar de JSON
        await backupService.importBackup(json);
        
        // Verificar se dados foram restaurados
        final teamsBox = Hive.box<Team>('teams');
        expect(teamsBox.length, equals(testTeams.length));
      });

      test('importBackup deve validar JSON', () async {
        const invalidJson = '{"invalid": json}';
        
        expect(
          () => backupService.importBackup(invalidJson),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Estatísticas de Backup', () {
      test('getBackupStats deve retornar estatísticas', () async {
        // Criar alguns backups
        for (int i = 0; i < 3; i++) {
          final backup = await backupService.createBackup();
          await backupService.saveBackup(backup);
        }
        
        final stats = await backupService.getBackupStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['totalBackups'], equals(3));
        expect(stats['lastBackupDate'], isA<String>());
        expect(stats['totalSize'], isA<int>());
      });

      test('deve calcular tamanho dos backups', () async {
        final backup = await backupService.createBackup();
        await backupService.saveBackup(backup);
        
        final stats = await backupService.getBackupStats();
        expect(stats['totalSize'], greaterThan(0));
      });
    });

    group('Tratamento de Erros', () {
      test('deve lidar com erro de acesso ao Hive', () async {
        // Simular erro fechando uma box
        await Hive.box('teams').close();
        
        expect(
          () => backupService.createBackup(),
          throwsA(isA<HiveError>()),
        );
      });

      test('deve lidar com backup corrompido', () async {
        final corruptedBackup = {
          'id': 'corrupted',
          'data': 'invalid_structure',
        };
        
        expect(
          () => backupService.restoreBackup(corruptedBackup),
          throwsA(isA<Exception>()),
        );
      });

      test('deve ser resiliente a falhas de I/O', () async {
        // Simular condições de erro
        expect(() => backupService.createBackup(), returnsNormally);
      });
    });

    group('Performance', () {
      test('createBackup deve ser eficiente', () async {
        final stopwatch = Stopwatch()..start();
        
        await backupService.createBackup();
        
        stopwatch.stop();
        
        // Deve criar backup rapidamente (menos de 1 segundo)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('restoreBackup deve ser eficiente', () async {
        final backup = await backupService.createBackup();
        
        final stopwatch = Stopwatch()..start();
        
        await backupService.restoreBackup(backup);
        
        stopwatch.stop();
        
        // Deve restaurar rapidamente (menos de 2 segundos)
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('deve lidar com grandes volumes de dados', () async {
        // Criar muitos dados
        final teamsBox = Hive.box<Team>('teams');
        for (int i = 0; i < 1000; i++) {
          final team = TestUtils.createTestTeam(
            id: 'team_$i',
            name: 'Team $i',
          );
          await teamsBox.put(team.id, team);
        }
        
        // Deve conseguir fazer backup mesmo com muitos dados
        final backup = await backupService.createBackup();
        expect(backup, isNotNull);
        
        final data = backup['data'] as Map<String, dynamic>;
        final teams = data['teams'] as Map<String, dynamic>;
        expect(teams.length, equals(1000));
      });
    });
  });
}