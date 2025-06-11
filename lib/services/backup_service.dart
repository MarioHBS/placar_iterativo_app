import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // Exportar apenas times
  Future<String> exportTeamsOnly() async {
    try {
      final teamsBox = await Hive.openBox<Team>('teams');
      final teams = <Map<String, dynamic>>[];

      for (final key in teamsBox.keys) {
        final team = teamsBox.get(key);
        if (team != null) {
          teams.add(_teamToJson(team));
        }
      }

      final backup = {
        'type': 'teams_only',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': teams,
      };

      return jsonEncode(backup);
    } catch (e) {
      throw Exception('Erro ao exportar times: $e');
    }
  }

  // Exportar backup completo (times + torneios)
  Future<String> exportComplete() async {
    try {
      final teamsBox = await Hive.openBox<Team>('teams');
      final tournamentsBox = await Hive.openBox<Tournament>('tournaments');
      
      final teams = <Map<String, dynamic>>[];
      final tournaments = <Map<String, dynamic>>[];

      // Exportar times
      for (final key in teamsBox.keys) {
        final team = teamsBox.get(key);
        if (team != null) {
          teams.add(_teamToJson(team));
        }
      }

      // Exportar torneios
      for (final key in tournamentsBox.keys) {
        final tournament = tournamentsBox.get(key);
        if (tournament != null) {
          tournaments.add(_tournamentToJson(tournament));
        }
      }

      final backup = {
        'type': 'complete',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': teams,
        'tournaments': tournaments,
      };

      return jsonEncode(backup);
    } catch (e) {
      throw Exception('Erro ao exportar backup completo: $e');
    }
  }

  // Importar apenas times
  Future<ImportResult> importTeams(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      if (!_validateTeamsBackup(data)) {
        throw Exception('Backup de times inválido');
      }

      final teamsBox = await Hive.openBox<Team>('teams');
      final teams = data['teams'] as List;
      int importedCount = 0;

      for (final teamData in teams) {
        final team = _teamFromJson(teamData);
        await teamsBox.put(team.id, team);
        importedCount++;
      }

      return ImportResult(
        success: true,
        teamsImported: importedCount,
        tournamentsImported: 0,
        message: 'Times importados com sucesso ($importedCount times)',
      );
    } catch (e) {
      return ImportResult(
        success: false,
        teamsImported: 0,
        tournamentsImported: 0,
        message: 'Erro ao importar times: $e',
      );
    }
  }

  // Importar backup completo com opção de torneios
  Future<ImportResult> importComplete(
    String jsonContent, {
    bool importTournaments = true,
  }) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      if (!_validateCompleteBackup(data)) {
        throw Exception('Backup completo inválido');
      }

      int teamsImported = 0;
      int tournamentsImported = 0;

      // OBRIGATÓRIO: Importar times
      final teamsBox = await Hive.openBox<Team>('teams');
      final teams = data['teams'] as List;
      
      for (final teamData in teams) {
        final team = _teamFromJson(teamData);
        await teamsBox.put(team.id, team);
        teamsImported++;
      }

      // OPCIONAL: Importar torneios
      if (importTournaments && data['tournaments'] != null) {
        final tournamentsBox = await Hive.openBox<Tournament>('tournaments');
        final tournaments = data['tournaments'] as List;
        
        for (final tournamentData in tournaments) {
          if (_validateTournamentReferences(tournamentData, teams)) {
            final tournament = _tournamentFromJson(tournamentData);
            await tournamentsBox.put(tournament.id, tournament);
            tournamentsImported++;
          }
        }
      }

      String message;
      if (importTournaments && tournamentsImported > 0) {
        message = 'Backup completo importado ($teamsImported times + $tournamentsImported torneios)';
      } else {
        message = 'Times importados com sucesso ($teamsImported times)';
      }

      return ImportResult(
        success: true,
        teamsImported: teamsImported,
        tournamentsImported: tournamentsImported,
        message: message,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        teamsImported: 0,
        tournamentsImported: 0,
        message: 'Erro ao importar backup: $e',
      );
    }
  }

  // Salvar arquivo de backup
  Future<String> saveBackupFile(String content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      throw Exception('Erro ao salvar arquivo: $e');
    }
  }

  // Validações
  bool _validateTeamsBackup(Map<String, dynamic> data) {
    return data['teams'] != null && 
           data['teams'] is List && 
           (data['teams'] as List).isNotEmpty;
  }

  bool _validateCompleteBackup(Map<String, dynamic> data) {
    return _validateTeamsBackup(data);
  }

  void _validateBackupFormat(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (data['type'] == null || data['version'] == null) {
        throw Exception('Formato de backup inválido');
      }
    } catch (e) {
      throw Exception('JSON inválido: $e');
    }
  }

  bool _validateTournamentReferences(Map<String, dynamic> tournamentData, List teams) {
    final teamIds = teams.map((t) => t['id']).toSet();
    final tournamentTeamIds = List<String>.from(tournamentData['teamIds'] ?? []);
    
    // Verificar se todos os times do torneio existem
    return tournamentTeamIds.every((id) => teamIds.contains(id));
  }

  // Conversões JSON (métodos públicos para testes)
  Map<String, dynamic> teamToJson(Team team) => _teamToJson(team);
  Team teamFromJson(Map<String, dynamic> json) => _teamFromJson(json);
  Map<String, dynamic> tournamentToJson(Tournament tournament) => _tournamentToJson(tournament);
  Tournament tournamentFromJson(Map<String, dynamic> json) => _tournamentFromJson(json);
  Map<String, dynamic> gameConfigToJson(GameConfig config) => _gameConfigToJson(config);
  GameConfig gameConfigFromJson(Map<String, dynamic> json) => _gameConfigFromJson(json);
  
  void validateBackupFormat(String jsonContent) => _validateBackupFormat(jsonContent);
  
  Map<String, dynamic> createTeamsOnlyBackup(List<Team> teams) {
    return {
      'type': 'teams_only',
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'teams': teams.map((team) => _teamToJson(team)).toList(),
    };
  }
  
  Map<String, dynamic> createCompleteBackup(List<Team> teams, List<Tournament> tournaments) {
    return {
      'type': 'complete',
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'teams': teams.map((team) => _teamToJson(team)).toList(),
      'tournaments': tournaments.map((tournament) => _tournamentToJson(tournament)).toList(),
    };
  }

  // Conversões JSON privadas
  Map<String, dynamic> _teamToJson(Team team) {
    return {
      'id': team.id,
      'name': team.name,
      'members': team.members,
      'emoji': team.emoji,
      'imagePath': team.imagePath,
      'color': team.color.value,
      'wins': team.wins,
      'losses': team.losses,
      'consecutiveWins': team.consecutiveWins,
      'isWaiting': team.isWaiting,
    };
  }

  Team _teamFromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      members: List<String>.from(json['members'] ?? []),
      emoji: json['emoji'],
      imagePath: json['imagePath'],
      color: Color(int.parse(json['color'])),
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      consecutiveWins: json['consecutiveWins'] ?? 0,
      isWaiting: json['isWaiting'] ?? false,
    );
  }

  Map<String, dynamic> _tournamentToJson(Tournament tournament) {
    return {
      'id': tournament.id,
      'name': tournament.name,
      'config': _gameConfigToJson(tournament.config),
      'teamIds': tournament.teamIds,
      'queueIds': tournament.queueIds,
      'waitingTeamId': tournament.waitingTeamId,
      'challengerId': tournament.challengerId,
      'matchIds': tournament.matchIds,
      'currentMatchId': tournament.currentMatchId,
      'createdAt': tournament.createdAt.toIso8601String(),
      'completedAt': tournament.completedAt?.toIso8601String(),
      'isComplete': tournament.isComplete,
    };
  }

  Tournament _tournamentFromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      config: _gameConfigFromJson(json['config']),
      teamIds: List<String>.from(json['teamIds'] ?? []),
      queueIds: List<String>.from(json['queueIds'] ?? []),
      waitingTeamId: json['waitingTeamId'],
      challengerId: json['challengerId'],
      matchIds: List<String>.from(json['matchIds'] ?? []),
      currentMatchId: json['currentMatchId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      isComplete: json['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> _gameConfigToJson(GameConfig config) {
    return {
      'id': config.id,
      'gameMode': config.gameMode.toString(),
      'endCondition': config.endCondition?.toString(),
      'timeLimit': config.timeLimit,
      'scoreLimit': config.scoreLimit,
      'winsForWaitingMode': config.winsForWaitingMode,
      'totalMatches': config.totalMatches,
      'waitingModeEnabled': config.waitingModeEnabled,
    };
  }

  GameConfig _gameConfigFromJson(Map<String, dynamic> json) {
    return GameConfig(
      id: json['id'] ?? '',
      gameMode: GameMode.values.firstWhere(
        (e) => e.toString() == json['gameMode'],
        orElse: () => GameMode.tournament,
      ),
      endCondition: json['endCondition'] != null 
          ? EndCondition.values.firstWhere(
              (e) => e.toString() == json['endCondition'],
              orElse: () => EndCondition.none,
            )
          : null,
      timeLimit: json['timeLimit'],
      scoreLimit: json['scoreLimit'],
      winsForWaitingMode: json['winsForWaitingMode'] ?? 3,
      totalMatches: json['totalMatches'],
      waitingModeEnabled: json['waitingModeEnabled'],
    );
  }
}

class ImportResult {
  final bool success;
  final int teamsImported;
  final int tournamentsImported;
  final String message;

  ImportResult({
    required this.success,
    required this.teamsImported,
    required this.tournamentsImported,
    required this.message,
  });
}