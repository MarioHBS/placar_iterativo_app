import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // Exportar apenas times
  Future<Map<String, dynamic>> exportTeamsOnly() async {
    try {
      final teamsBox = await Hive.openBox<Team>('teams');
      final teams = <Map<String, dynamic>>[];
      final teamObjects = <Team>[];

      for (final key in teamsBox.keys) {
        final team = teamsBox.get(key);
        if (team != null) {
          teams.add(_teamToJson(team));
          teamObjects.add(team);
        }
      }

      final backup = {
        'type': 'teams_only',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'teams': teams,
      };

      return {
        'jsonContent': jsonEncode(backup),
        'teams': teamObjects,
      };
    } catch (e) {
      throw Exception('Erro ao exportar times: $e');
    }
  }

  // Exportar backup completo (times + torneios)
  Future<Map<String, dynamic>> exportComplete() async {
    try {
      final teamsBox = await Hive.openBox<Team>('teams');
      final tournamentsBox = await Hive.openBox<Tournament>('tournaments');
      
      final teams = <Map<String, dynamic>>[];
      final tournaments = <Map<String, dynamic>>[];
      final teamObjects = <Team>[];

      // Exportar times
      for (final key in teamsBox.keys) {
        final team = teamsBox.get(key);
        if (team != null) {
          teams.add(_teamToJson(team));
          teamObjects.add(team);
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

      return {
        'jsonContent': jsonEncode(backup),
        'teams': teamObjects,
      };
    } catch (e) {
      throw Exception('Erro ao exportar backup completo: $e');
    }
  }

  // Importar apenas times
  Future<ImportResult> importTeams(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      if (!_validateTeamsBackup(data)) {
        return ImportResult(
          success: false,
          teamsImported: 0,
          tournamentsImported: 0,
          message: 'Formato de backup inválido para times.',
        );
      }

      final teamsBox = await Hive.openBox<Team>('teams');
      final teams = data['teams'] as List<dynamic>;
      int importedCount = 0;

      for (final teamData in teams) {
        try {
          final team = _teamFromJson(teamData as Map<String, dynamic>);
          await teamsBox.put(team.id, team);
          importedCount++;
        } catch (e) {
          print('Erro ao importar time: $e');
        }
      }

      return ImportResult(
        success: true,
        teamsImported: importedCount,
        tournamentsImported: 0,
        message: 'Times importados com sucesso! ($importedCount times)',
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
  
  // Importar times de arquivo (JSON ou ZIP)
  Future<ImportResult> importTeamsFromFile(File file) async {
    try {
      final fileName = file.path.toLowerCase();
      
      if (fileName.endsWith('.zip')) {
        return await _importFromZip(file, teamsOnly: true);
      } else {
        final content = await file.readAsString();
        return await importTeams(content);
      }
    } catch (e) {
      return ImportResult(
        success: false,
        teamsImported: 0,
        tournamentsImported: 0,
        message: 'Erro ao importar arquivo: $e',
      );
    }
  }
   
   // Importar backup completo de arquivo (JSON ou ZIP)
   Future<ImportResult> importCompleteFromFile(File file, {bool importTournaments = true}) async {
     try {
       final fileName = file.path.toLowerCase();
       
       if (fileName.endsWith('.zip')) {
         return await _importFromZip(file, teamsOnly: false, importTournaments: importTournaments);
       } else {
         final content = await file.readAsString();
         return await importComplete(content, importTournaments: importTournaments);
       }
     } catch (e) {
       return ImportResult(
         success: false,
         teamsImported: 0,
         tournamentsImported: 0,
         message: 'Erro ao importar arquivo: $e',
       );
     }
   }
   
   // Importar de arquivo ZIP
   Future<ImportResult> _importFromZip(File zipFile, {required bool teamsOnly, bool importTournaments = true}) async {
     try {
       final bytes = await zipFile.readAsBytes();
       final archive = ZipDecoder().decodeBytes(bytes);
       
       // Encontrar o arquivo JSON no ZIP
       ArchiveFile? jsonFile;
       for (final file in archive) {
         if (file.name == 'backup.json') {
           jsonFile = file;
           break;
         }
       }
       
       if (jsonFile == null) {
         return ImportResult(
           success: false,
           teamsImported: 0,
           tournamentsImported: 0,
           message: 'Arquivo backup.json não encontrado no ZIP.',
         );
       }
       
       // Extrair e processar o JSON
       final jsonContent = utf8.decode(jsonFile.content as List<int>);
       
       // Extrair imagens para diretório temporário
       final tempDir = await getTemporaryDirectory();
       final imagesDir = Directory('${tempDir.path}/backup_images_${DateTime.now().millisecondsSinceEpoch}');
       await imagesDir.create(recursive: true);
       
       final imageMapping = <String, String>{};
       
       for (final file in archive) {
         if (file.name.startsWith('images/') && file.name != 'images/') {
           final imageName = file.name.substring(7); // Remove 'images/' prefix
           final imageFile = File('${imagesDir.path}/$imageName');
           await imageFile.writeAsBytes(file.content as List<int>);
           imageMapping[imageName] = imageFile.path;
         }
       }
       
       // Importar dados com mapeamento de imagens
       ImportResult result;
       if (teamsOnly) {
         result = await _importTeamsWithImages(jsonContent, imageMapping);
       } else {
         result = await _importCompleteWithImages(jsonContent, imageMapping, importTournaments: importTournaments);
       }
       
       return result;
     } catch (e) {
       return ImportResult(
         success: false,
         teamsImported: 0,
         tournamentsImported: 0,
         message: 'Erro ao processar arquivo ZIP: $e',
       );
     }
   }
    
    // Importar times com imagens
    Future<ImportResult> _importTeamsWithImages(String jsonContent, Map<String, String> imageMapping) async {
      try {
        final data = jsonDecode(jsonContent) as Map<String, dynamic>;
        
        if (!_validateTeamsBackup(data)) {
          return ImportResult(
            success: false,
            teamsImported: 0,
            tournamentsImported: 0,
            message: 'Formato de backup inválido para times.',
          );
        }

        final teamsBox = await Hive.openBox<Team>('teams');
        final teams = data['teams'] as List<dynamic>;
        int importedCount = 0;

        for (final teamData in teams) {
          try {
            final team = await _teamFromJsonWithImages(teamData as Map<String, dynamic>, imageMapping);
            await teamsBox.put(team.id, team);
            importedCount++;
          } catch (e) {
            print('Erro ao importar time: $e');
          }
        }

        return ImportResult(
          success: true,
          teamsImported: importedCount,
          tournamentsImported: 0,
          message: 'Times importados com sucesso! ($importedCount times)',
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
    
    // Importar backup completo com imagens
    Future<ImportResult> _importCompleteWithImages(String jsonContent, Map<String, String> imageMapping, {bool importTournaments = true}) async {
      try {
        final data = jsonDecode(jsonContent) as Map<String, dynamic>;
        
        if (!_validateCompleteBackup(data)) {
          return ImportResult(
            success: false,
            teamsImported: 0,
            tournamentsImported: 0,
            message: 'Formato de backup completo inválido.',
          );
        }

        final teamsBox = await Hive.openBox<Team>('teams');
        final tournamentsBox = await Hive.openBox<Tournament>('tournaments');
        
        final teams = data['teams'] as List<dynamic>;
        final tournaments = data['tournaments'] as List<dynamic>;
        
        int teamsImported = 0;
        int tournamentsImported = 0;

        // Importar times com imagens
        for (final teamData in teams) {
          try {
            final team = await _teamFromJsonWithImages(teamData as Map<String, dynamic>, imageMapping);
            await teamsBox.put(team.id, team);
            teamsImported++;
          } catch (e) {
            print('Erro ao importar time: $e');
          }
        }

        // Importar torneios se solicitado
        if (importTournaments) {
          for (final tournamentData in tournaments) {
            try {
              final tournament = _tournamentFromJson(tournamentData as Map<String, dynamic>);
              await tournamentsBox.put(tournament.id, tournament);
              tournamentsImported++;
            } catch (e) {
              print('Erro ao importar torneio: $e');
            }
          }
        }

        return ImportResult(
          success: true,
          teamsImported: teamsImported,
          tournamentsImported: tournamentsImported,
          message: 'Backup importado com sucesso! ($teamsImported times, $tournamentsImported torneios)',
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
    
    // Converter team de JSON com restauração de imagens
    Future<Team> _teamFromJsonWithImages(Map<String, dynamic> json, Map<String, String> imageMapping) async {
      String? finalImagePath;
      
      if (json['imagePath'] != null && json['imagePath'].toString().isNotEmpty) {
        final originalImagePath = json['imagePath'] as String;
        final imageName = 'team_${json['id']}_${originalImagePath.split(Platform.pathSeparator).last}';
        
        if (imageMapping.containsKey(imageName)) {
          // Copiar imagem para diretório permanente
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/team_images');
          await imagesDir.create(recursive: true);
          
          final tempImageFile = File(imageMapping[imageName]!);
          final permanentImageFile = File('${imagesDir.path}/$imageName');
          
          await tempImageFile.copy(permanentImageFile.path);
          finalImagePath = permanentImageFile.path;
        }
      }
      
      return Team(
        id: json['id'],
        name: json['name'],
        members: List<String>.from(json['members'] ?? []),
        emoji: json['emoji'],
        imagePath: finalImagePath,
        color: Color(json['color'] is String ? int.parse(json['color']) : json['color']),
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        consecutiveWins: json['consecutiveWins'] ?? 0,
        isWaiting: json['isWaiting'] ?? false,
      );
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
  Future<String> saveBackupFile(String content, String filename, [List<Team>? teams]) async {
    try {
      Directory backupDir;
      
      if (Platform.isAndroid) {
        // No Android, usar o diretório de downloads público
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navegar para o diretório público de downloads
          final publicDir = Directory('/storage/emulated/0/Download/Placar_Iterativo');
          backupDir = publicDir;
        } else {
          // Fallback para diretório de documentos da aplicação
          final appDir = await getApplicationDocumentsDirectory();
          backupDir = Directory('${appDir.path}/Placar_Iterativo');
        }
      } else if (Platform.isWindows) {
        // No Windows, usar pasta na raiz C:\
        backupDir = Directory('C:\\Placar_Iterativo');
      } else {
        // Para outras plataformas (iOS, macOS, Linux), usar documentos da aplicação
        final appDir = await getApplicationDocumentsDirectory();
        backupDir = Directory('${appDir.path}/Placar_Iterativo');
      }
      
      // Criar o diretório se não existir
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Verificar se há imagens para incluir no backup
      final teamImages = teams != null ? await _collectTeamImages(teams) : <String, Uint8List>{};
      
      if (teamImages.isNotEmpty) {
        // Criar arquivo ZIP com JSON e imagens
        final zipFilename = filename.replaceAll('.json', '.zip');
        final zipPath = await _createZipBackup(backupDir.path, zipFilename, content, teamImages);
        return zipPath;
      } else {
        // Salvar apenas o arquivo JSON
        final file = File('${backupDir.path}${Platform.pathSeparator}$filename');
        await file.writeAsString(content);
        return file.path;
      }
    } catch (e) {
      throw Exception('Erro ao salvar arquivo: $e');
    }
  }
  
  // Coletar imagens dos times
  Future<Map<String, Uint8List>> _collectTeamImages(List<Team> teams) async {
    final images = <String, Uint8List>{};
    
    for (final team in teams) {
      if (team.imagePath != null && team.imagePath!.isNotEmpty) {
        try {
          final file = File(team.imagePath!);
          if (await file.exists()) {
            final imageBytes = await file.readAsBytes();
            final imageName = 'team_${team.id}_${file.path.split(Platform.pathSeparator).last}';
            images[imageName] = imageBytes;
          }
        } catch (e) {
          print('Erro ao ler imagem do time ${team.name}: $e');
        }
      }
    }
    
    return images;
  }
  
  // Criar arquivo ZIP com backup e imagens
  Future<String> _createZipBackup(String backupDirPath, String zipFilename, String jsonContent, Map<String, Uint8List> images) async {
    final archive = Archive();
    
    // Adicionar arquivo JSON ao ZIP
    final jsonBytes = utf8.encode(jsonContent);
    final jsonFile = ArchiveFile('backup.json', jsonBytes.length, jsonBytes);
    archive.addFile(jsonFile);
    
    // Adicionar imagens ao ZIP
    for (final entry in images.entries) {
      final imageFile = ArchiveFile('images/${entry.key}', entry.value.length, entry.value);
      archive.addFile(imageFile);
    }
    
    // Criar arquivo ZIP
    final zipBytes = ZipEncoder().encode(archive);
    final zipFile = File('$backupDirPath${Platform.pathSeparator}$zipFilename');
    await zipFile.writeAsBytes(zipBytes!);
    
    return zipFile.path;
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
      color: Color(json['color'] is String ? int.parse(json['color']) : json['color']),
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