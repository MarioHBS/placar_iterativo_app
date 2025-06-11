import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/services/backup_service.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:flutter/material.dart';

void main() {
  group('BackupService Tests', () {
    late BackupService backupService;
    late Box<Team> teamsBox;
    late Box<Tournament> tournamentsBox;

    setUpAll(() async {
      // Initialize Hive for testing without Flutter dependencies
      Hive.init('test');
      
      // Initialize HiveService with all adapters
      await HiveService.init(isTest: true);
    });

    setUp(() async {
      backupService = BackupService();
      
      // Open test boxes
      teamsBox = await Hive.openBox<Team>('test_teams');
      tournamentsBox = await Hive.openBox<Tournament>('test_tournaments');
      
      // Clear boxes before each test
      await teamsBox.clear();
      await tournamentsBox.clear();
    });

    tearDown(() async {
      await teamsBox.close();
      await tournamentsBox.close();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    test('should export teams only', () async {
      // Arrange
      final team1 = Team(
        id: '1',
        name: 'Team A',
        members: ['Player 1', 'Player 2'],
        color: Colors.red,
      );
      final team2 = Team(
        id: '2',
        name: 'Team B',
        members: ['Player 3', 'Player 4'],
        color: Colors.blue,
      );
      
      await teamsBox.put('1', team1);
      await teamsBox.put('2', team2);

      // Act
      final jsonContent = await backupService.exportTeamsOnly();
      final data = jsonDecode(jsonContent);

      // Assert
      expect(data['type'], 'teams_only');
      expect(data['version'], '1.0');
      expect(data['teams'], hasLength(2));
      expect(data['teams'][0]['name'], 'Team A');
      expect(data['teams'][1]['name'], 'Team B');
      expect(data.containsKey('tournaments'), false);
    });

    test('should export complete backup', () async {
      // Arrange
      final team1 = Team(
        id: '1',
        name: 'Team A',
        members: ['Player 1', 'Player 2'],
        color: Colors.red,
      );
      
      final gameConfig = GameConfig(
        id: 'config1',
        gameMode: GameMode.tournament,
        endCondition: EndCondition.score,
        scoreLimit: 10,
        timeLimit: 300,
        winsForWaitingMode: 3,
      );
      
      final tournament = Tournament(
        id: 'tournament1',
        name: 'Test Tournament',
        config: gameConfig,
        teamIds: ['1'],
        queueIds: [],
        matchIds: [],
      );
      
      await teamsBox.put('1', team1);
      await tournamentsBox.put('tournament1', tournament);

      // Act
      final jsonContent = await backupService.exportComplete();
      final data = jsonDecode(jsonContent);

      // Assert
      expect(data['type'], 'complete');
      expect(data['version'], '1.0');
      expect(data['teams'], hasLength(1));
      expect(data['tournaments'], hasLength(1));
      expect(data['teams'][0]['name'], 'Team A');
      expect(data['tournaments'][0]['name'], 'Test Tournament');
    });

    test('should import teams successfully', () async {
      // Arrange
      final backupData = {
        'type': 'teams_only',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': [
          {
            'id': '1',
            'name': 'Imported Team',
            'members': ['Player 1'],
            'color': 0xFF4CAF50,
            'wins': 0,
            'losses': 0,
            'consecutiveWins': 0,
            'isWaiting': false,
          }
        ]
      };
      
      final jsonContent = jsonEncode(backupData);

      // Act
      final result = await backupService.importTeams(jsonContent);

      // Assert
      expect(result.success, true);
      expect(result.message, contains('1 time(s) importado(s)'));
      
      final importedTeam = teamsBox.get('1');
      expect(importedTeam, isNotNull);
      expect(importedTeam!.name, 'Imported Team');
    });

    test('should import complete backup with teams only', () async {
      // Arrange
      final team1 = Team(
        id: '1',
        name: 'Team A',
        members: ['Player 1'],
        color: Colors.red,
      );
      
      final gameConfig = GameConfig(
        id: 'config1',
        gameMode: GameMode.tournament,
        endCondition: EndCondition.score,
        scoreLimit: 10,
        timeLimit: 300,
        winsForWaitingMode: 3,
      );
      
      final tournament = Tournament(
        id: 'tournament1',
        name: 'Test Tournament',
        config: gameConfig,
        teamIds: ['1'],
        queueIds: [],
        matchIds: [],
      );
      
      final backupData = {
        'type': 'complete',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': [backupService.teamToJson(team1)],
        'tournaments': [backupService.tournamentToJson(tournament)]
      };
      
      final jsonContent = jsonEncode(backupData);

      // Act - Import teams only
      final result = await backupService.importComplete(
        jsonContent,
        importTournaments: false,
      );

      // Assert
      expect(result.success, true);
      expect(result.message, contains('1 time(s) importado(s)'));
      expect(result.message, contains('Torneios não foram importados'));
      
      final importedTeam = teamsBox.get('1');
      expect(importedTeam, isNotNull);
      expect(importedTeam!.name, 'Team A');
      
      final importedTournament = tournamentsBox.get('tournament1');
      expect(importedTournament, isNull);
    });

    test('should import complete backup with teams and tournaments', () async {
      // Arrange
      final team1 = Team(
        id: '1',
        name: 'Team A',
        members: ['Player 1'],
        color: Colors.red,
      );
      
      final gameConfig = GameConfig(
        id: 'config1',
        gameMode: GameMode.tournament,
        endCondition: EndCondition.score,
        scoreLimit: 10,
        timeLimit: 300,
        winsForWaitingMode: 3,
      );
      
      final tournament = Tournament(
        id: 'tournament1',
        name: 'Test Tournament',
        config: gameConfig,
        teamIds: ['1'],
        queueIds: [],
        matchIds: [],
      );
      
      final backupData = {
        'type': 'complete',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': [backupService.teamToJson(team1)],
        'tournaments': [backupService.tournamentToJson(tournament)]
      };
      
      final jsonContent = jsonEncode(backupData);

      // Act - Import everything
      final result = await backupService.importComplete(
        jsonContent,
        importTournaments: true,
      );

      // Assert
      expect(result.success, true);
      expect(result.message, contains('1 time(s) importado(s)'));
      expect(result.message, contains('1 torneio(s) importado(s)'));
      
      final importedTeam = teamsBox.get('1');
      expect(importedTeam, isNotNull);
      expect(importedTeam!.name, 'Team A');
      
      final importedTournament = tournamentsBox.get('tournament1');
      expect(importedTournament, isNotNull);
      expect(importedTournament!.name, 'Test Tournament');
    });

    test('should validate backup format', () async {
      // Arrange
      final invalidJson = '{"invalid": "format"}';

      // Act & Assert
      expect(
        () => backupService.importTeams(invalidJson),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle missing teams in tournament backup', () async {
      // Arrange
      final gameConfig = GameConfig(
        id: 'config1',
        gameMode: GameMode.tournament,
        endCondition: EndCondition.score,
        scoreLimit: 10,
        timeLimit: 300,
        winsForWaitingMode: 3,
      );
      
      final tournament = Tournament(
        id: 'tournament1',
        name: 'Test Tournament',
        config: gameConfig,
        teamIds: ['nonexistent_team'],
        queueIds: [],
        matchIds: [],
      );
      
      final backupData = {
        'type': 'complete',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': [],
        'tournaments': [backupService.tournamentToJson(tournament)]
      };
      
      final jsonContent = jsonEncode(backupData);

      // Act & Assert
      expect(
        () => backupService.importComplete(jsonContent, importTournaments: true),
        throwsA(isA<Exception>()),
      );
    });
  });
}