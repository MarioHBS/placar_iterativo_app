import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import '../test_utils.dart';

void main() {
  group('TeamsProvider Tests', () {
    late TeamsNotifier teamsProvider;
    late Box<Team> teamsBox;

    setUp(() async {
      await TestUtils.initializeHiveForTesting();
      teamsBox = await Hive.openBox<Team>('teams');
      teamsProvider = TeamsNotifier();
      
      // Aguardar inicialização
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Inicialização', () {
      test('deve inicializar com estado correto', () {
        expect(teamsProvider.teams, isA<Map<String, Team>>());
        expect(teamsProvider.isLoading, isFalse);
        expect(teamsProvider.error, isNull);
      });

      test('deve carregar times existentes do Hive', () async {
        // Adicionar times diretamente no Hive
        final team1 = TestUtils.createTestTeam(id: 'team1', name: 'Team 1');
        final team2 = TestUtils.createTestTeam(id: 'team2', name: 'Team 2');
        
        await teamsBox.put('team1', team1);
        await teamsBox.put('team2', team2);
        
        // Criar novo provider para carregar dados
        final newProvider = TeamsNotifier();
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(newProvider.teams.length, equals(2));
        expect(newProvider.teams['team1']?.name, equals('Team 1'));
        expect(newProvider.teams['team2']?.name, equals('Team 2'));
      });
    });

    group('Criação de Times', () {
      test('createTeam deve criar um novo time', () async {
        final team = await teamsProvider.createTeam(
          name: 'New Team',
          members: ['Player 1', 'Player 2'],
          color: Colors.blue,
        );
        
        expect(team.name, equals('New Team'));
        expect(team.members, equals(['Player 1', 'Player 2']));
        expect(team.color, equals(Colors.blue));
        expect(teamsProvider.teams.containsKey(team.id), isTrue);
      });

      test('createTeam deve gerar nome automático quando não fornecido', () async {
        final team = await teamsProvider.createTeam();
        
        expect(team.name, startsWith('Time '));
        expect(team.color, isA<Color>());
        expect(teamsProvider.teams.containsKey(team.id), isTrue);
      });

      test('createTeam deve persistir no Hive', () async {
        final team = await teamsProvider.createTeam(name: 'Persistent Team');
        
        final savedTeam = teamsBox.get(team.id);
        expect(savedTeam, isNotNull);
        expect(savedTeam!.name, equals('Persistent Team'));
      });

      test('createTeam deve notificar listeners', () async {
        bool notified = false;
        teamsProvider.addListener(() {
          notified = true;
        });
        
        await teamsProvider.createTeam(name: 'Notification Test');
        
        expect(notified, isTrue);
      });
    });

    group('Atualização de Times', () {
      late Team testTeam;

      setUp(() async {
        testTeam = await teamsProvider.createTeam(
          name: 'Test Team',
          members: ['Player 1'],
          color: Colors.red,
        );
      });

      test('updateTeam deve atualizar propriedades do time', () async {
        await teamsProvider.updateTeam(
          testTeam.id,
          name: 'Updated Team',
          members: ['Player 1', 'Player 2'],
          color: Colors.green,
        );
        
        final updatedTeam = teamsProvider.teams[testTeam.id];
        expect(updatedTeam?.name, equals('Updated Team'));
        expect(updatedTeam?.members, equals(['Player 1', 'Player 2']));
        expect(updatedTeam?.color, equals(Colors.green));
      });

      test('updateTeam deve persistir mudanças no Hive', () async {
        await teamsProvider.updateTeam(
          testTeam.id,
          name: 'Persistent Update',
        );
        
        final savedTeam = teamsBox.get(testTeam.id);
        expect(savedTeam?.name, equals('Persistent Update'));
      });

      test('updateTeam deve notificar listeners', () async {
        bool notified = false;
        teamsProvider.addListener(() {
          notified = true;
        });
        
        await teamsProvider.updateTeam(testTeam.id, name: 'Notification Update');
        
        expect(notified, isTrue);
      });

      test('updateTeam deve retornar false para time inexistente', () async {
        final result = await teamsProvider.updateTeam(
          'nonexistent_id',
          name: 'Should Fail',
        );
        
        expect(result, isFalse);
      });
    });

    group('Remoção de Times', () {
      late Team testTeam;

      setUp(() async {
        testTeam = await teamsProvider.createTeam(name: 'Team to Delete');
      });

      test('deleteTeam deve remover time', () async {
        final result = await teamsProvider.deleteTeam(testTeam.id);
        
        expect(result, isTrue);
        expect(teamsProvider.teams.containsKey(testTeam.id), isFalse);
      });

      test('deleteTeam deve remover do Hive', () async {
        await teamsProvider.deleteTeam(testTeam.id);
        
        final savedTeam = teamsBox.get(testTeam.id);
        expect(savedTeam, isNull);
      });

      test('deleteTeam deve notificar listeners', () async {
        bool notified = false;
        teamsProvider.addListener(() {
          notified = true;
        });
        
        await teamsProvider.deleteTeam(testTeam.id);
        
        expect(notified, isTrue);
      });

      test('deleteTeam deve retornar false para time inexistente', () async {
        final result = await teamsProvider.deleteTeam('nonexistent_id');
        
        expect(result, isFalse);
      });
    });

    group('Consultas de Times', () {
      setUp(() async {
        // Criar times de teste
        await teamsProvider.createTeam(
          name: 'Team Alpha',
          color: Colors.red,
          wins: 10,
          losses: 2,
        );
        await teamsProvider.createTeam(
          name: 'Team Beta',
          color: Colors.blue,
          wins: 5,
          losses: 5,
        );
        await teamsProvider.createTeam(
          name: 'Team Gamma',
          color: Colors.green,
          wins: 8,
          losses: 3,
        );
      });

      test('getTeam deve retornar time por ID', () {
        final teams = teamsProvider.getAllTeams();
        final firstTeam = teams.first;
        
        final retrievedTeam = teamsProvider.getTeam(firstTeam.id);
        expect(retrievedTeam, equals(firstTeam));
      });

      test('getTeam deve retornar null para ID inexistente', () {
        final retrievedTeam = teamsProvider.getTeam('nonexistent_id');
        expect(retrievedTeam, isNull);
      });

      test('getAllTeams deve retornar todos os times', () {
        final teams = teamsProvider.getAllTeams();
        expect(teams.length, equals(3));
      });

      test('getTeamsByColor deve filtrar por cor', () {
        final redTeams = teamsProvider.getTeamsByColor(Colors.red);
        expect(redTeams.length, equals(1));
        expect(redTeams.first.name, equals('Team Alpha'));
      });

      test('searchTeams deve buscar por nome', () {
        final alphaTeams = teamsProvider.searchTeams('Alpha');
        expect(alphaTeams.length, equals(1));
        expect(alphaTeams.first.name, equals('Team Alpha'));
        
        final teamResults = teamsProvider.searchTeams('Team');
        expect(teamResults.length, equals(3));
      });

      test('getTopTeams deve retornar times com melhor performance', () {
        final topTeams = teamsProvider.getTopTeams(limit: 2);
        expect(topTeams.length, equals(2));
        
        // Verificar se estão ordenados por taxa de vitórias
        expect(topTeams.first.winRate, greaterThanOrEqualTo(topTeams.last.winRate));
      });

      test('getTeamsCount deve retornar número correto', () {
        expect(teamsProvider.getTeamsCount(), equals(3));
      });
    });

    group('Estatísticas de Times', () {
      late Team testTeam;

      setUp(() async {
        testTeam = await teamsProvider.createTeam(
          name: 'Stats Team',
          wins: 5,
          losses: 3,
        );
      });

      test('addWin deve incrementar vitórias', () async {
        await teamsProvider.addWin(testTeam.id);
        
        final updatedTeam = teamsProvider.getTeam(testTeam.id);
        expect(updatedTeam?.wins, equals(6));
        expect(updatedTeam?.consecutiveWins, equals(1));
      });

      test('addLoss deve incrementar derrotas', () async {
        await teamsProvider.addLoss(testTeam.id);
        
        final updatedTeam = teamsProvider.getTeam(testTeam.id);
        expect(updatedTeam?.losses, equals(4));
        expect(updatedTeam?.consecutiveWins, equals(0));
      });

      test('resetTeamStats deve zerar estatísticas', () async {
        await teamsProvider.resetTeamStats(testTeam.id);
        
        final updatedTeam = teamsProvider.getTeam(testTeam.id);
        expect(updatedTeam?.wins, equals(0));
        expect(updatedTeam?.losses, equals(0));
        expect(updatedTeam?.consecutiveWins, equals(0));
      });

      test('resetAllStats deve zerar estatísticas de todos os times', () async {
        await teamsProvider.resetAllStats();
        
        final teams = teamsProvider.getAllTeams();
        for (final team in teams) {
          expect(team.wins, equals(0));
          expect(team.losses, equals(0));
          expect(team.consecutiveWins, equals(0));
        }
      });
    });

    group('Importação e Exportação', () {
      setUp(() async {
        // Criar times de teste
        await teamsProvider.createTeam(name: 'Export Team 1');
        await teamsProvider.createTeam(name: 'Export Team 2');
      });

      test('exportTeams deve retornar dados de todos os times', () {
        final exportData = teamsProvider.exportTeams();
        
        expect(exportData, isA<List<Map<String, dynamic>>>());
        expect(exportData.length, equals(2));
        expect(exportData.any((data) => data['name'] == 'Export Team 1'), isTrue);
        expect(exportData.any((data) => data['name'] == 'Export Team 2'), isTrue);
      });

      test('importTeams deve importar dados de times', () async {
        final importData = [
          {
            'id': 'import1',
            'name': 'Import Team 1',
            'color': Colors.purple.value,
            'wins': 3,
            'losses': 1,
          },
          {
            'id': 'import2',
            'name': 'Import Team 2',
            'color': Colors.orange.value,
            'wins': 2,
            'losses': 4,
          },
        ];
        
        await teamsProvider.importTeams(importData);
        
        expect(teamsProvider.getTeamsCount(), equals(4)); // 2 existentes + 2 importados
        expect(teamsProvider.getTeam('import1')?.name, equals('Import Team 1'));
        expect(teamsProvider.getTeam('import2')?.name, equals('Import Team 2'));
      });

      test('importTeams deve substituir times existentes', () async {
        final existingTeam = teamsProvider.getAllTeams().first;
        
        final importData = [
          {
            'id': existingTeam.id,
            'name': 'Replaced Team',
            'color': Colors.yellow.value,
            'wins': 100,
            'losses': 0,
          },
        ];
        
        await teamsProvider.importTeams(importData);
        
        final replacedTeam = teamsProvider.getTeam(existingTeam.id);
        expect(replacedTeam?.name, equals('Replaced Team'));
        expect(replacedTeam?.wins, equals(100));
      });
    });

    group('Tratamento de Erros', () {
      test('deve lidar com erros de inicialização', () async {
        // Simular erro fechando o box
        await teamsBox.close();
        
        final errorProvider = TeamsNotifier();
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(errorProvider.error, isNotNull);
        expect(errorProvider.isLoading, isFalse);
      });

      test('deve lidar com operações em times inexistentes', () async {
        final result1 = await teamsProvider.addWin('nonexistent');
        final result2 = await teamsProvider.addLoss('nonexistent');
        final result3 = await teamsProvider.resetTeamStats('nonexistent');
        
        expect(result1, isFalse);
        expect(result2, isFalse);
        expect(result3, isFalse);
      });
    });

    group('Notificações', () {
      test('deve notificar listeners em todas as operações', () async {
        int notificationCount = 0;
        teamsProvider.addListener(() {
          notificationCount++;
        });
        
        await teamsProvider.createTeam(name: 'Notification Test');
        final team = teamsProvider.getAllTeams().first;
        
        await teamsProvider.updateTeam(team.id, name: 'Updated');
        await teamsProvider.addWin(team.id);
        await teamsProvider.addLoss(team.id);
        await teamsProvider.deleteTeam(team.id);
        
        expect(notificationCount, greaterThan(0));
      });
    });
  });
}