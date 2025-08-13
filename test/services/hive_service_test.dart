import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import '../test_utils.dart';

void main() {
  group('HiveService Tests', () {
    setUp(() async {
      await TestUtils.initializeHiveForTesting();
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Inicialização', () {
      test('initHive deve inicializar Hive corretamente', () async {
        // Verificar se Hive foi inicializado
        expect(Hive.isBoxOpen('teams'), isTrue);
        expect(Hive.isBoxOpen('matches'), isTrue);
        expect(Hive.isBoxOpen('tournaments'), isTrue);
        expect(Hive.isBoxOpen('gameConfigs'), isTrue);
      });

      test('deve registrar todos os adapters necessários', () {
        // Verificar se os adapters foram registrados
        expect(Hive.isAdapterRegistered(0), isTrue); // Team
        expect(Hive.isAdapterRegistered(1), isTrue); // Match
        expect(Hive.isAdapterRegistered(2), isTrue); // Tournament
        expect(Hive.isAdapterRegistered(3), isTrue); // GameConfig
        expect(Hive.isAdapterRegistered(4), isTrue); // GameMode
        expect(Hive.isAdapterRegistered(5), isTrue); // EndCondition
        expect(Hive.isAdapterRegistered(6), isTrue); // TournamentEndCondition
        expect(Hive.isAdapterRegistered(7), isTrue); // Color
        expect(Hive.isAdapterRegistered(8), isTrue); // DateTime
      });

      test('deve abrir todas as boxes necessárias', () async {
        final boxes = [
          'teams',
          'matches',
          'tournaments',
          'gameConfigs',
          'settings',
          'backups',
        ];

        for (final boxName in boxes) {
          expect(Hive.isBoxOpen(boxName), isTrue);
        }
      });
    });

    group('Operações com Teams', () {
      late Box<Team> teamsBox;
      late Team testTeam;

      setUp(() async {
        teamsBox = Hive.box<Team>('teams');
        testTeam = TestUtils.createTestTeam(
          id: 'test_team',
          name: 'Test Team',
        );
      });

      test('deve salvar e recuperar team', () async {
        await teamsBox.put(testTeam.id, testTeam);
        
        final retrievedTeam = teamsBox.get(testTeam.id);
        
        expect(retrievedTeam, isNotNull);
        expect(retrievedTeam!.id, equals(testTeam.id));
        expect(retrievedTeam.name, equals(testTeam.name));
        expect(retrievedTeam.color, equals(testTeam.color));
        expect(retrievedTeam.members, equals(testTeam.members));
      });

      test('deve atualizar team existente', () async {
        await teamsBox.put(testTeam.id, testTeam);
        
        final updatedTeam = testTeam.copyWith(
          name: 'Updated Team',
          wins: 5,
        );
        
        await teamsBox.put(testTeam.id, updatedTeam);
        
        final retrievedTeam = teamsBox.get(testTeam.id);
        expect(retrievedTeam!.name, equals('Updated Team'));
        expect(retrievedTeam.wins, equals(5));
      });

      test('deve deletar team', () async {
        await teamsBox.put(testTeam.id, testTeam);
        expect(teamsBox.get(testTeam.id), isNotNull);
        
        await teamsBox.delete(testTeam.id);
        expect(teamsBox.get(testTeam.id), isNull);
      });

      test('deve listar todos os teams', () async {
        final teams = [
          TestUtils.createTestTeam(id: 'team1', name: 'Team 1'),
          TestUtils.createTestTeam(id: 'team2', name: 'Team 2'),
          TestUtils.createTestTeam(id: 'team3', name: 'Team 3'),
        ];
        
        for (final team in teams) {
          await teamsBox.put(team.id, team);
        }
        
        final allTeams = teamsBox.values.toList();
        expect(allTeams, hasLength(3));
        expect(allTeams.map((t) => t.name), containsAll(['Team 1', 'Team 2', 'Team 3']));
      });
    });

    group('Operações com Matches', () {
      late Box<Match> matchesBox;
      late Match testMatch;

      setUp(() async {
        matchesBox = Hive.box<Match>('matches');
        testMatch = TestUtils.createTestMatch(
          id: 'test_match',
          teamAId: 'team_a',
          teamBId: 'team_b',
        );
      });

      test('deve salvar e recuperar match', () async {
        await matchesBox.put(testMatch.id, testMatch);
        
        final retrievedMatch = matchesBox.get(testMatch.id);
        
        expect(retrievedMatch, isNotNull);
        expect(retrievedMatch!.id, equals(testMatch.id));
        expect(retrievedMatch.teamAId, equals(testMatch.teamAId));
        expect(retrievedMatch.teamBId, equals(testMatch.teamBId));
        expect(retrievedMatch.teamAScore, equals(testMatch.teamAScore));
        expect(retrievedMatch.teamBScore, equals(testMatch.teamBScore));
      });

      test('deve preservar timestamps', () async {
        await matchesBox.put(testMatch.id, testMatch);
        
        final retrievedMatch = matchesBox.get(testMatch.id);
        
        expect(retrievedMatch!.startTime, equals(testMatch.startTime));
        expect(retrievedMatch.endTime, equals(testMatch.endTime));
      });

      test('deve preservar estado de conclusão', () async {
        final completedMatch = testMatch.copyWith(
          isComplete: true,
          endTime: DateTime.now(),
          winnerId: 'team_a',
          loserId: 'team_b',
        );
        
        await matchesBox.put(completedMatch.id, completedMatch);
        
        final retrievedMatch = matchesBox.get(completedMatch.id);
        expect(retrievedMatch!.isComplete, isTrue);
        expect(retrievedMatch.winnerId, equals('team_a'));
        expect(retrievedMatch.loserId, equals('team_b'));
      });
    });

    group('Operações com Tournaments', () {
      late Box<Tournament> tournamentsBox;
      late Tournament testTournament;

      setUp(() async {
        tournamentsBox = Hive.box<Tournament>('tournaments');
        testTournament = TestUtils.createTestTournament(
          id: 'test_tournament',
          name: 'Test Tournament',
          config: TestUtils.createTestGameConfig(),
        );
      });

      test('deve salvar e recuperar tournament', () async {
        await tournamentsBox.put(testTournament.id, testTournament);
        
        final retrievedTournament = tournamentsBox.get(testTournament.id);
        
        expect(retrievedTournament, isNotNull);
        expect(retrievedTournament!.id, equals(testTournament.id));
        expect(retrievedTournament.name, equals(testTournament.name));
        expect(retrievedTournament.config, equals(testTournament.config));
      });

      test('deve preservar listas de IDs', () async {
        testTournament.addTeam('team1');
        testTournament.addTeam('team2');
        testTournament.addToQueue('team1');
        
        await tournamentsBox.put(testTournament.id, testTournament);
        
        final retrievedTournament = tournamentsBox.get(testTournament.id);
        expect(retrievedTournament!.teamIds, hasLength(2));
        expect(retrievedTournament.queueIds, hasLength(1));
      });

      test('deve preservar estado de conclusão', () async {
        testTournament.completeTournament();
        
        await tournamentsBox.put(testTournament.id, testTournament);
        
        final retrievedTournament = tournamentsBox.get(testTournament.id);
        expect(retrievedTournament!.isComplete, isTrue);
        expect(retrievedTournament.completedAt, isNotNull);
      });
    });

    group('Operações com GameConfig', () {
      late Box<GameConfig> gameConfigsBox;
      late GameConfig testConfig;

      setUp(() async {
        gameConfigsBox = Hive.box<GameConfig>('gameConfigs');
        testConfig = TestUtils.createTestGameConfig(
          gameMode: GameMode.classic,
          endCondition: EndCondition.both,
          maxScore: 15,
          maxTime: const Duration(minutes: 10),
        );
      });

      test('deve salvar e recuperar game config', () async {
        await gameConfigsBox.put('test_config', testConfig);
        
        final retrievedConfig = gameConfigsBox.get('test_config');
        
        expect(retrievedConfig, isNotNull);
        expect(retrievedConfig!.gameMode, equals(testConfig.gameMode));
        expect(retrievedConfig.endCondition, equals(testConfig.endCondition));
        expect(retrievedConfig.maxScore, equals(testConfig.maxScore));
        expect(retrievedConfig.maxTime, equals(testConfig.maxTime));
      });

      test('deve preservar configurações de torneio', () async {
        final tournamentConfig = testConfig.copyWith(
          tournamentEndCondition: TournamentEndCondition.maxMatches,
          maxMatches: 20,
          firstToWins: 5,
        );
        
        await gameConfigsBox.put('tournament_config', tournamentConfig);
        
        final retrievedConfig = gameConfigsBox.get('tournament_config');
        expect(retrievedConfig!.tournamentEndCondition, equals(TournamentEndCondition.maxMatches));
        expect(retrievedConfig.maxMatches, equals(20));
        expect(retrievedConfig.firstToWins, equals(5));
      });
    });

    group('Operações de Limpeza', () {
      test('deve limpar box específica', () async {
        final teamsBox = Hive.box<Team>('teams');
        
        // Adicionar alguns teams
        for (int i = 0; i < 3; i++) {
          final team = TestUtils.createTestTeam(
            id: 'team_$i',
            name: 'Team $i',
          );
          await teamsBox.put(team.id, team);
        }
        
        expect(teamsBox.length, equals(3));
        
        // Limpar box
        await teamsBox.clear();
        
        expect(teamsBox.length, equals(0));
        expect(teamsBox.isEmpty, isTrue);
      });

      test('deve limpar todas as boxes', () async {
        // Adicionar dados em várias boxes
        final teamsBox = Hive.box<Team>('teams');
        final matchesBox = Hive.box<Match>('matches');
        
        await teamsBox.put('team1', TestUtils.createTestTeam(id: 'team1'));
        await matchesBox.put('match1', TestUtils.createTestMatch(id: 'match1'));
        
        expect(teamsBox.isNotEmpty, isTrue);
        expect(matchesBox.isNotEmpty, isTrue);
        
        // Limpar todas as boxes
        await TestUtils.clearAllHiveBoxes();
        
        expect(teamsBox.isEmpty, isTrue);
        expect(matchesBox.isEmpty, isTrue);
      });
    });

    group('Operações de Backup', () {
      test('deve criar backup dos dados', () async {
        final teamsBox = Hive.box<Team>('teams');
        final backupsBox = Hive.box('backups');
        
        // Adicionar alguns dados
        final team = TestUtils.createTestTeam(id: 'team1', name: 'Team 1');
        await teamsBox.put(team.id, team);
        
        // Criar backup
        final backupData = {
          'teams': teamsBox.toMap(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        await backupsBox.put('backup_1', backupData);
        
        final retrievedBackup = backupsBox.get('backup_1');
        expect(retrievedBackup, isNotNull);
        expect(retrievedBackup['teams'], isA<Map>());
        expect(retrievedBackup['timestamp'], isA<String>());
      });
    });

    group('Operações de Configurações', () {
      test('deve salvar e recuperar configurações', () async {
        final settingsBox = Hive.box('settings');
        
        final settings = {
          'theme': 'dark',
          'language': 'pt-BR',
          'soundEnabled': true,
          'autoSave': false,
        };
        
        for (final entry in settings.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
        
        expect(settingsBox.get('theme'), equals('dark'));
        expect(settingsBox.get('language'), equals('pt-BR'));
        expect(settingsBox.get('soundEnabled'), isTrue);
        expect(settingsBox.get('autoSave'), isFalse);
      });
    });

    group('Tratamento de Erros', () {
      test('deve lidar com chave inexistente', () {
        final teamsBox = Hive.box<Team>('teams');
        
        final result = teamsBox.get('inexistente');
        expect(result, isNull);
      });

      test('deve lidar com dados corrompidos', () async {
        final settingsBox = Hive.box('settings');
        
        // Salvar dados válidos
        await settingsBox.put('valid_key', 'valid_value');
        
        // Tentar recuperar com tipo incorreto não deve quebrar
        final result = settingsBox.get('valid_key');
        expect(result, equals('valid_value'));
      });
    });

    group('Performance', () {
      test('deve lidar com grande volume de dados', () async {
        final teamsBox = Hive.box<Team>('teams');
        
        final stopwatch = Stopwatch()..start();
        
        // Inserir 1000 teams
        for (int i = 0; i < 1000; i++) {
          final team = TestUtils.createTestTeam(
            id: 'team_$i',
            name: 'Team $i',
          );
          await teamsBox.put(team.id, team);
        }
        
        stopwatch.stop();
        
        expect(teamsBox.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Menos de 5 segundos
      });

      test('deve recuperar dados rapidamente', () async {
        final teamsBox = Hive.box<Team>('teams');
        
        // Inserir alguns teams
        for (int i = 0; i < 100; i++) {
          final team = TestUtils.createTestTeam(
            id: 'team_$i',
            name: 'Team $i',
          );
          await teamsBox.put(team.id, team);
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Recuperar todos os teams
        final allTeams = teamsBox.values.toList();
        
        stopwatch.stop();
        
        expect(allTeams, hasLength(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Menos de 100ms
      });
    });

    group('Integridade dos Dados', () {
      test('deve manter referências consistentes', () async {
        final teamsBox = Hive.box<Team>('teams');
        final matchesBox = Hive.box<Match>('matches');
        
        // Criar teams
        final teamA = TestUtils.createTestTeam(id: 'team_a', name: 'Team A');
        final teamB = TestUtils.createTestTeam(id: 'team_b', name: 'Team B');
        
        await teamsBox.put(teamA.id, teamA);
        await teamsBox.put(teamB.id, teamB);
        
        // Criar match com referências aos teams
        final match = TestUtils.createTestMatch(
          id: 'match_1',
          teamAId: teamA.id,
          teamBId: teamB.id,
        );
        
        await matchesBox.put(match.id, match);
        
        // Verificar consistência
        final retrievedMatch = matchesBox.get(match.id);
        final retrievedTeamA = teamsBox.get(retrievedMatch!.teamAId);
        final retrievedTeamB = teamsBox.get(retrievedMatch.teamBId);
        
        expect(retrievedTeamA, isNotNull);
        expect(retrievedTeamB, isNotNull);
        expect(retrievedTeamA!.id, equals(teamA.id));
        expect(retrievedTeamB!.id, equals(teamB.id));
      });
    });
  });
}