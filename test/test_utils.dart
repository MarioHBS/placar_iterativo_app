import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import 'package:placar_iterativo_app/app_module.dart';

/// Utilitários para facilitar a criação e execução de testes
class TestUtils {
  /// Inicializa o Hive para testes
  static Future<void> initializeHiveForTesting() async {
    Hive.init('test_hive');
    HiveService.registerAdapters();
  }

  /// Limpa todas as boxes do Hive
  static Future<void> clearAllHiveBoxes() async {
    await Hive.deleteFromDisk();
  }

  /// Cria um widget de teste com providers necessários
  static Widget createTestWidget(Widget child, {bool withModular = false}) {
    if (withModular) {
      return ModularApp(
        module: AppModule(),
        child: MaterialApp(
          home: child,
        ),
      );
    }
    
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Cria um team de teste
  static Team createTestTeam({
    String? id,
    String? name,
    List<String>? members,
    Color? color,
    int wins = 0,
    int losses = 0,
  }) {
    return Team(
      id: id ?? 'test_team_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Team',
      members: members ?? ['Player 1', 'Player 2'],
      color: color ?? Colors.blue,
      wins: wins,
      losses: losses,
    );
  }

  /// Cria uma partida de teste
  static Match createTestMatch({
    String? id,
    String? teamAId,
    String? teamBId,
    int teamAScore = 0,
    int teamBScore = 0,
    bool isComplete = false,
  }) {
    return Match(
      id: id ?? 'test_match_${DateTime.now().millisecondsSinceEpoch}',
      teamAId: teamAId ?? 'team_a',
      teamBId: teamBId ?? 'team_b',
      teamAScore: teamAScore,
      teamBScore: teamBScore,
      startTime: DateTime.now(),
      isComplete: isComplete,
    );
  }

  /// Cria uma configuração de jogo de teste
  static GameConfig createTestGameConfig({
    String? id,
    GameMode gameMode = GameMode.tournament,
    EndCondition? endCondition,
  }) {
    return GameConfig(
      id: id ?? 'test_config_${DateTime.now().millisecondsSinceEpoch}',
      gameMode: gameMode,
      endCondition: endCondition,
    );
  }

  /// Cria um torneio de teste
  static Tournament createTestTournament({
    String? id,
    String? name,
    GameConfig? config,
    List<String>? teamIds,
    List<String>? queueIds,
  }) {
    final defaultTeamIds = teamIds ?? ['team1', 'team2'];
    return Tournament(
      id: id ?? 'test_tournament_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Tournament',
      config: config ?? createTestGameConfig(),
      teamIds: defaultTeamIds,
      queueIds: queueIds ?? List<String>.from(defaultTeamIds),
    );
  }

  /// Verifica se um widget existe
  static void verifyWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifica se um widget não existe
  static void verifyWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Simula um tap em um widget
  static Future<void> tapWidget(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Simula entrada de texto
  static Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Aguarda animações terminarem
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Simula mudança de orientação
  static Future<void> changeOrientation(WidgetTester tester, Orientation orientation) async {
    final size = orientation == Orientation.portrait
        ? const Size(400, 800)
        : const Size(800, 400);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpAndSettle();
  }

  /// Matcher customizado para verificar cores
  static Matcher hasColor(Color expectedColor) {
    return predicate<Widget>((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final decoration = widget.decoration as BoxDecoration;
        return decoration.color == expectedColor;
      }
      return false;
    }, 'has color $expectedColor');
  }

  /// Matcher customizado para verificar texto
  static Matcher hasText(String expectedText) {
    return predicate<Widget>((widget) {
      if (widget is Text) {
        return widget.data == expectedText;
      }
      return false;
    }, 'has text "$expectedText"');
  }

  /// Converte team para JSON (para testes de serialização)
  static Map<String, dynamic> teamToJson(Team team) {
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
      'tournamentConsecutiveWins': team.tournamentConsecutiveWins,
    };
  }

  /// Converte um Tournament para JSON (método auxiliar para testes)
  static Map<String, dynamic> tournamentToJson(Tournament tournament) {
    return {
      'id': tournament.id,
      'name': tournament.name,
      'teamIds': tournament.teamIds,
      'queueIds': tournament.queueIds,
      'isComplete': tournament.isComplete,
      'config': tournament.config,
    };
  }

  /// Converte um Match para JSON (método auxiliar para testes)
  static Map<String, dynamic> matchToJson(Match match) {
    return {
      'id': match.id,
      'teamAId': match.teamAId,
      'teamBId': match.teamBId,
      'teamAScore': match.teamAScore,
      'teamBScore': match.teamBScore,
      'startTime': match.startTime.toIso8601String(),
      'endTime': match.endTime?.toIso8601String(),
      'isComplete': match.isComplete,
    };
  }

  /// Converte um GameConfig para JSON (método auxiliar para testes)
  static Map<String, dynamic> gameConfigToJson(GameConfig config) {
    return {
      'id': config.id,
      'gameMode': config.gameMode.index,
      'endCondition': config.endCondition?.index,
      'timeLimit': config.timeLimit,
      'scoreLimit': config.scoreLimit,
      'winsForWaitingMode': config.winsForWaitingMode,
      'totalMatches': config.totalMatches,
      'waitingModeEnabled': config.waitingModeEnabled,
      'tournamentEndCondition': config.tournamentEndCondition?.index,
      'firstToWinsCount': config.firstToWinsCount,
      'roundsCount': config.roundsCount,
      'targetPoints': config.targetPoints,
      'tournamentDurationMinutes': config.tournamentDurationMinutes,
      'specificDeadline': config.specificDeadline?.toIso8601String(),
      'maxTournamentMatches': config.maxTournamentMatches,
      'maxScore': config.maxScore,
      'maxTime': config.maxTime?.inMilliseconds,
    };
  }

  /// Cria um GameConfig a partir de JSON (método auxiliar para testes)
  static GameConfig gameConfigFromJson(Map<String, dynamic> json) {
    return GameConfig(
      id: json['id'],
      gameMode: json['gameMode'] is int ? GameMode.values[json['gameMode']] : GameMode.tournament,
      endCondition: json['endCondition'] != null 
          ? (json['endCondition'] is int ? EndCondition.values[json['endCondition']] : null)
          : null,
      timeLimit: json['timeLimit'],
      scoreLimit: json['scoreLimit'],
      winsForWaitingMode: json['winsForWaitingMode'] ?? 3,
      totalMatches: json['totalMatches'],
      waitingModeEnabled: json['waitingModeEnabled'],
      tournamentEndCondition: json['tournamentEndCondition'] != null
          ? (json['tournamentEndCondition'] is int ? TournamentEndCondition.values[json['tournamentEndCondition']] : null)
          : null,
      firstToWinsCount: json['firstToWinsCount'],
      roundsCount: json['roundsCount'],
      targetPoints: json['targetPoints'],
      tournamentDurationMinutes: json['tournamentDurationMinutes'],
      specificDeadline: json['specificDeadline'] != null
          ? DateTime.parse(json['specificDeadline'])
          : null,
      maxTournamentMatches: json['maxTournamentMatches'],
      maxScore: json['maxScore'],
      maxTime: json['maxTime'] != null ? Duration(milliseconds: json['maxTime']) : null,
    );
  }
}

/// Mocks para testes
class MockData {
  static List<Team> get sampleTeams => [
    TestUtils.createTestTeam(
      id: 'team1',
      name: 'Team Alpha',
      color: Colors.red,
      wins: 5,
      losses: 2,
    ),
    TestUtils.createTestTeam(
      id: 'team2',
      name: 'Team Beta',
      color: Colors.blue,
      wins: 3,
      losses: 4,
    ),
    TestUtils.createTestTeam(
      id: 'team3',
      name: 'Team Gamma',
      color: Colors.green,
      wins: 7,
      losses: 1,
    ),
  ];

  static List<Match> get sampleMatches => [
    TestUtils.createTestMatch(
      id: 'match1',
      teamAId: 'team1',
      teamBId: 'team2',
      teamAScore: 10,
      teamBScore: 8,
      isComplete: true,
    ),
    TestUtils.createTestMatch(
      id: 'match2',
      teamAId: 'team2',
      teamBId: 'team3',
      teamAScore: 5,
      teamBScore: 12,
      isComplete: true,
    ),
    TestUtils.createTestMatch(
      id: 'match3',
      teamAId: 'team1',
      teamBId: 'team3',
      teamAScore: 3,
      teamBScore: 7,
      isComplete: false,
    ),
  ];
}
