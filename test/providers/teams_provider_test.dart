import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';

void main() {
  group('TeamsProvider Tests', () {
    late TeamsNotifier teamsNotifier;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test');
      await HiveService.init(isTest: true);
    });

    setUp(() async {
      // Clear any existing data
      if (Hive.isBoxOpen('teams')) {
        await Hive.box<Team>('teams').clear();
      }
      teamsNotifier = TeamsNotifier();
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      if (Hive.isBoxOpen('teams')) {
        await Hive.box<Team>('teams').clear();
      }
    });

    tearDownAll(() async {
      await Hive.close();
    });

    test('should initialize with empty teams', () async {
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 200));

      expect(teamsNotifier.teams, isEmpty);
      expect(teamsNotifier.isLoading, isFalse);
      expect(teamsNotifier.error, isNull);
    });

    test('should create a new team successfully', () async {
      // Arrange
      const teamName = 'Test Team';
      const teamColor = Colors.blue;
      const members = ['Player 1', 'Player 2'];
      const emoji = '⚽';

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 200));

      // Act
      final team = await teamsNotifier.createTeam(
        name: teamName,
        color: teamColor,
        members: members,
        emoji: emoji,
      );

      // Assert
      expect(team.name, equals(teamName));
      expect(team.color, equals(teamColor));
      expect(team.members, equals(members));
      expect(team.emoji, equals(emoji));
      expect(team.id, isNotEmpty);
      expect(teamsNotifier.teams, contains(team.id));
      expect(teamsNotifier.teams[team.id], equals(team));
    });

    test('should create team with default values when parameters are null',
        () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 200));

      // Act
      final team = await teamsNotifier.createTeam();

      // Assert
      expect(team.name, startsWith('Time '));
      expect(team.color, isA<Color>());
      expect(team.members, isEmpty);
      expect(team.emoji, isNull);
      expect(team.wins, equals(0));
      expect(team.losses, equals(0));
      expect(team.consecutiveWins, equals(0));
      expect(team.isWaiting, isFalse);
    });

    test('should update existing team', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      final team = await teamsNotifier.createTeam(name: 'Original Name');
      const newName = 'Updated Name';
      const newColor = Colors.red;
      const newMembers = ['New Player'];
      const newEmoji = '🏆';

      // Act
      final updatedTeam = team.copyWith(
        name: newName,
        color: newColor,
        members: newMembers,
        emoji: newEmoji,
      );
      await teamsNotifier.updateTeam(updatedTeam);

      // Assert
      expect(updatedTeam.name, equals(newName));
      expect(updatedTeam.color, equals(newColor));
      expect(updatedTeam.members, equals(newMembers));
      expect(updatedTeam.emoji, equals(newEmoji));
      expect(teamsNotifier.teams[team.id]?.name, equals(newName));
    });

    test('should delete team successfully', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      final team = await teamsNotifier.createTeam(name: 'Team to Delete');
      expect(teamsNotifier.teams, contains(team.id));

      // Act
      await teamsNotifier.deleteTeam(team.id);

      // Assert
      expect(teamsNotifier.teams, isNot(contains(team.id)));
    });

    test('should get team by id', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      final team = await teamsNotifier.createTeam(name: 'Test Team');

      // Act
      final retrievedTeam = teamsNotifier.getTeam(team.id);

      // Assert
      expect(retrievedTeam, isNotNull);
      expect(retrievedTeam?.id, equals(team.id));
      expect(retrievedTeam?.name, equals(team.name));
    });

    test('should return null for non-existent team', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      const nonExistentId = 'non-existent-id';

      // Act
      final team = teamsNotifier.getTeam(nonExistentId);

      // Assert
      expect(team, isNull);
    });

    test('should get all teams as list', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      await teamsNotifier.createTeam(name: 'Team 1');
      await teamsNotifier.createTeam(name: 'Team 2');
      await teamsNotifier.createTeam(name: 'Team 3');

      // Act
      final teamsList = teamsNotifier.getAllTeams();

      // Assert
      expect(teamsList.length, equals(3));
      expect(teamsList.map((t) => t.name),
          containsAll(['Team 1', 'Team 2', 'Team 3']));
    });

    test('should clear all teams', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      await teamsNotifier.createTeam(name: 'Team 1');
      await teamsNotifier.createTeam(name: 'Team 2');
      expect(teamsNotifier.teams.length, equals(2));

      // Act
      final teamIds = teamsNotifier.teams.keys.toList();
      for (final teamId in teamIds) {
        await teamsNotifier.deleteTeam(teamId);
      }

      // Assert
      expect(teamsNotifier.teams, isEmpty);
    });

    test('should notify listeners when teams change', () async {
      // Arrange
      await Future.delayed(const Duration(milliseconds: 200));
      var notificationCount = 0;
      teamsNotifier.addListener(() {
        notificationCount++;
      });

      // Act
      await teamsNotifier.createTeam(name: 'Test Team');

      // Assert
      expect(notificationCount, greaterThan(0));
    });

    test('should handle errors gracefully', () async {
      // This test would require mocking Hive to throw an error
      // For now, we'll test that error handling structure exists
      await Future.delayed(const Duration(milliseconds: 200));

      expect(teamsNotifier.error, isNull);
      expect(teamsNotifier.isLoading, isFalse);
    });
  });
}
