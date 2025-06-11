import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/services/backup_service.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:flutter/material.dart';

void main() {
  group('BackupService JSON Conversion Tests', () {
    late BackupService backupService;

    setUp(() {
      backupService = BackupService();
    });

    test('should convert Team to JSON and back', () {
      // Arrange
      final team = Team(
        id: '1',
        name: 'Test Team',
        members: ['Player 1', 'Player 2'],
        color: Colors.red,
      );

      // Act
      final json = backupService.teamToJson(team);
      final teamFromJson = backupService.teamFromJson(json);

      // Assert
      expect(teamFromJson.id, team.id);
      expect(teamFromJson.name, team.name);
      expect(teamFromJson.members, team.members);
      expect(teamFromJson.color, team.color);
      expect(teamFromJson.wins, team.wins);
      expect(teamFromJson.losses, team.losses);
      expect(teamFromJson.consecutiveWins, team.consecutiveWins);
    });

    test('should convert GameConfig to JSON and back', () {
      // Arrange
      final gameConfig = GameConfig(
        id: 'config1',
        gameMode: GameMode.tournament,
        endCondition: EndCondition.score,
        scoreLimit: 10,
        timeLimit: 300,
        winsForWaitingMode: 3,
      );

      // Act
      final json = backupService.gameConfigToJson(gameConfig);
      final configFromJson = backupService.gameConfigFromJson(json);

      // Assert
      expect(configFromJson.id, gameConfig.id);
      expect(configFromJson.gameMode, gameConfig.gameMode);
      expect(configFromJson.endCondition, gameConfig.endCondition);
      expect(configFromJson.scoreLimit, gameConfig.scoreLimit);
      expect(configFromJson.timeLimit, gameConfig.timeLimit);
      expect(configFromJson.winsForWaitingMode, gameConfig.winsForWaitingMode);
    });

    test('should convert Tournament to JSON and back', () {
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
        teamIds: ['team1', 'team2'],
        queueIds: [],
        matchIds: [],
      );

      // Act
      final json = backupService.tournamentToJson(tournament);
      final tournamentFromJson = backupService.tournamentFromJson(json);

      // Assert
      expect(tournamentFromJson.id, tournament.id);
      expect(tournamentFromJson.name, tournament.name);
      expect(tournamentFromJson.teamIds, tournament.teamIds);
      expect(tournamentFromJson.queueIds, tournament.queueIds);
      expect(tournamentFromJson.matchIds, tournament.matchIds);
      expect(tournamentFromJson.config.id, tournament.config.id);
      expect(tournamentFromJson.config.scoreLimit, tournament.config.scoreLimit);
    });

    test('should validate teams only backup format', () {
      // Arrange
      final validBackup = {
        'type': 'teams_only',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': [
          {
            'id': '1',
            'name': 'Test Team',
            'members': ['Player 1'],
            'color': '0xFFFF0000',
            'wins': 0,
            'losses': 0,
            'consecutiveWins': 0,
            'isWaiting': false,
          }
        ]
      };
      
      final jsonContent = jsonEncode(validBackup);

      // Act & Assert
      expect(() => backupService.validateBackupFormat(jsonContent), returnsNormally);
    });

    test('should validate complete backup format', () {
      // Arrange
      final validBackup = {
        'type': 'complete',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': [
          {
            'id': '1',
            'name': 'Test Team',
            'members': ['Player 1'],
            'color': '0xFFFF0000',
            'wins': 0,
            'losses': 0,
            'consecutiveWins': 0,
            'isWaiting': false,
          }
        ],
        'tournaments': [
          {
            'id': 'tournament1',
            'name': 'Test Tournament',
            'teamIds': ['1'],
            'matchIds': [],
            'config': {
              'maxScore': 10,
              'timeLimit': 300,
              'enableTimeLimit': true,
            }
          }
        ]
      };
      
      final jsonContent = jsonEncode(validBackup);

      // Act & Assert
      expect(() => backupService.validateBackupFormat(jsonContent), returnsNormally);
    });

    test('should throw exception for invalid backup format', () {
      // Arrange
      final invalidBackup = {
        'invalid': 'format'
      };
      
      final jsonContent = jsonEncode(invalidBackup);

      // Act & Assert
      expect(
        () => backupService.validateBackupFormat(jsonContent),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for missing required fields', () {
      // Arrange
      final incompleteBackup = {
        'type': 'teams_only',
        'version': '1.0',
        // Missing exportDate and teams
      };
      
      final jsonContent = jsonEncode(incompleteBackup);

      // Act & Assert
      expect(
        () => backupService.validateBackupFormat(jsonContent),
        throwsA(isA<Exception>()),
      );
    });

    test('should create proper teams only backup structure', () {
      // Arrange
      final teams = [
        Team(
          id: '1',
          name: 'Team A',
          members: ['Player 1'],
          color: Colors.red,
        ),
        Team(
          id: '2',
          name: 'Team B',
          members: ['Player 2'],
          color: Colors.blue,
        ),
      ];

      // Act
      final backupData = backupService.createTeamsOnlyBackup(teams);

      // Assert
      expect(backupData['type'], 'teams_only');
      expect(backupData['version'], '1.0');
      expect(backupData['teams'], hasLength(2));
      expect(backupData['teams'][0]['name'], 'Team A');
      expect(backupData['teams'][1]['name'], 'Team B');
      expect(backupData.containsKey('tournaments'), false);
    });

    test('should create proper complete backup structure', () {
      // Arrange
      final teams = [
        Team(
          id: '1',
          name: 'Team A',
          members: ['Player 1'],
          color: Colors.red,
        ),
      ];
      
      final tournaments = [
        Tournament(
          id: 'tournament1',
          name: 'Test Tournament',
          config: GameConfig(
            id: 'config1',
            gameMode: GameMode.tournament,
            endCondition: EndCondition.score,
            scoreLimit: 10,
            timeLimit: 300,
          ),
          teamIds: ['1'],
          queueIds: [],
        ),
      ];

      // Act
      final backupData = backupService.createCompleteBackup(teams, tournaments);

      // Assert
      expect(backupData['type'], 'complete');
      expect(backupData['version'], '1.0');
      expect(backupData['teams'], hasLength(1));
      expect(backupData['tournaments'], hasLength(1));
      expect(backupData['teams'][0]['name'], 'Team A');
      expect(backupData['tournaments'][0]['name'], 'Test Tournament');
    });
  });
}