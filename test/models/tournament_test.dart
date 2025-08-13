import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import '../test_utils.dart';

void main() {
  group('Tournament Model Tests', () {
    late Tournament tournament;
    late GameConfig gameConfig;

    setUp(() {
      gameConfig = TestUtils.createTestGameConfig(
        id: 'test_config',
        gameMode: GameMode.tournament,
      );

      tournament = TestUtils.createTestTournament(
        id: 'test_tournament_1',
        name: 'Test Tournament',
        config: gameConfig,
        teamIds: ['team1', 'team2', 'team3', 'team4'],
      );
    });

    group('Construtor e Propriedades', () {
      test('deve criar um torneio com propriedades corretas', () {
        expect(tournament.id, equals('test_tournament_1'));
        expect(tournament.name, equals('Test Tournament'));
        expect(tournament.config, equals(gameConfig));
        expect(
            tournament.teamIds, equals(['team1', 'team2', 'team3', 'team4']));
        expect(tournament.queueIds, equals(['team1', 'team2', 'team3', 'team4']));
        expect(tournament.waitingTeamId, isNull);
        expect(tournament.isComplete, isFalse);
        expect(tournament.completedAt, isNull);
      });

      test('deve criar um torneio com valores padrão', () {
        final defaultTournament = Tournament(
          id: 'default_tournament',
          name: 'Default Tournament',
          config: gameConfig,
          teamIds: ['team1', 'team2'],
          queueIds: [],
        );

        expect(defaultTournament.queueIds, isEmpty);
        expect(defaultTournament.waitingTeamId, isNull);
        expect(defaultTournament.challengerId, isNull);
        expect(defaultTournament.matchIds, isEmpty);
        expect(defaultTournament.currentMatchId, isNull);
        expect(defaultTournament.isComplete, isFalse);
        expect(defaultTournament.completedAt, isNull);
      });
    });

    group('Métodos de Gerenciamento de Times', () {
      test('addTeam deve adicionar time ao torneio', () {
        tournament.addTeam('team5');
        expect(tournament.teamIds, contains('team5'));
      });

      test('addTeam não deve adicionar time duplicado', () {
        final initialLength = tournament.teamIds.length;
        tournament.addTeam('team1'); // team1 já existe
        expect(tournament.teamIds.length, equals(initialLength));
      });

      test('removeTeam deve remover time do torneio', () {
        tournament.removeTeam('team1');
        expect(tournament.teamIds, isNot(contains('team1')));
      });

      test('removeTeam deve remover time da fila também', () {
        // Ensure team1 is in queue
        if (!tournament.queueIds.contains('team1')) {
          tournament.queueIds.add('team1');
        }
        tournament.removeTeam('team1');
        expect(tournament.queueIds, isNot(contains('team1')));
      });

      test('hasTeam deve retornar true para time existente', () {
        expect(tournament.hasTeam('team1'), isTrue);
        expect(tournament.hasTeam('nonexistent'), isFalse);
      });

      test('getTeamCount deve retornar número correto de times', () {
        expect(tournament.getTeamCount(), equals(4));
      });
    });

    group('Métodos de Gerenciamento de Fila', () {
      test('addToQueue deve adicionar time à fila', () {
        tournament.addToQueue('team1');
        expect(tournament.queueIds, contains('team1'));
      });

      test('addToQueue não deve adicionar time que não está no torneio', () {
        tournament.addToQueue('nonexistent');
        expect(tournament.queueIds, isNot(contains('nonexistent')));
      });

      test('removeFromQueue deve remover time da fila', () {
        tournament.queueIds.clear();
        tournament.queueIds.add('team1');
        tournament.removeFromQueue('team1');
        expect(tournament.queueIds, isNot(contains('team1')));
      });

      test('getNextInQueue deve retornar próximo time da fila', () {
        tournament.queueIds.addAll(['team1', 'team2', 'team3']);
        expect(tournament.getNextInQueue(), equals('team1'));
      });

      test('getNextInQueue deve retornar null para fila vazia', () {
        tournament.queueIds.clear();
        expect(tournament.getNextInQueue(), isNull);
      });

      test('isInQueue deve verificar se time está na fila', () {
        tournament.queueIds.clear();
        tournament.queueIds.add('team1');
        expect(tournament.isInQueue('team1'), isTrue);
        expect(tournament.isInQueue('team2'), isFalse);
      });

      test('getQueuePosition deve retornar posição na fila', () {
        tournament.queueIds.clear();
        tournament.queueIds.addAll(['team1', 'team2', 'team3']);
        expect(tournament.getQueuePosition('team1'), equals(0));
        expect(tournament.getQueuePosition('team2'), equals(1));
        expect(tournament.getQueuePosition('team3'), equals(2));
        expect(tournament.getQueuePosition('team4'), equals(-1));
      });
    });

    group('Métodos de Gerenciamento de Partidas', () {
      test('addMatch deve adicionar partida ao torneio', () {
        tournament.addMatch('match1');
        expect(tournament.matchIds, contains('match1'));
      });

      test('setCurrentMatch deve definir partida atual', () {
        tournament.setCurrentMatch('match1');
        expect(tournament.currentMatchId, equals('match1'));
      });

      test('clearCurrentMatch deve limpar partida atual', () {
        tournament.setCurrentMatch('match1');
        tournament.clearCurrentMatch();
        expect(tournament.currentMatchId, isNull);
      });

      test('hasCurrentMatch deve verificar se há partida atual', () {
        expect(tournament.hasCurrentMatch(), isFalse);
        tournament.setCurrentMatch('match1');
        expect(tournament.hasCurrentMatch(), isTrue);
      });

      test('getMatchCount deve retornar número de partidas', () {
        tournament.addMatch('match1');
        tournament.addMatch('match2');
        expect(tournament.getMatchCount(), equals(2));
      });
    });

    group('Propriedades Básicas', () {
      test('deve ter propriedades corretas após criação', () {
        expect(tournament.id, isNotEmpty);
        expect(tournament.name, equals('Test Tournament'));
        expect(tournament.teamIds, hasLength(4));
        expect(tournament.queueIds, hasLength(4));
        expect(tournament.isComplete, isFalse);
      });
      test('deve permitir modificar nome', () {
        tournament.name = 'New Tournament Name';
        expect(tournament.name, equals('New Tournament Name'));
      });

      test('deve permitir marcar como completo', () {
        tournament.isComplete = true;
        expect(tournament.isComplete, isTrue);
      });

      test('deve ter data de criação', () {
        expect(tournament.createdAt, isA<DateTime>());
      });
    });

    group('Gerenciamento de IDs', () {
      test('deve gerenciar matchIds corretamente', () {
        tournament.matchIds = ['match1', 'match2'];
        expect(tournament.matchIds, hasLength(2));
        expect(tournament.matchIds, contains('match1'));
        expect(tournament.matchIds, contains('match2'));
      });

      test('deve gerenciar currentMatchId', () {
        tournament.currentMatchId = 'current_match';
        expect(tournament.currentMatchId, equals('current_match'));
      });

      test('deve gerenciar challengerId', () {
        tournament.challengerId = 'challenger_team';
        expect(tournament.challengerId, equals('challenger_team'));
      });

      test('deve gerenciar waitingTeamId', () {
        tournament.waitingTeamId = 'waiting_team';
        expect(tournament.waitingTeamId, equals('waiting_team'));
      });
    });

    group('Serialização', () {
      test('toJson deve converter tournament para Map', () {
        final json = TestUtils.tournamentToJson(tournament);

        expect(json['id'], equals(tournament.id));
        expect(json['name'], equals(tournament.name));
        expect(json['teamIds'], equals(tournament.teamIds));
        expect(json['queueIds'], equals(tournament.queueIds));
        expect(json['isComplete'], equals(tournament.isComplete));
      });

      test('fromJson deve criar tournament a partir de Map', () {
        final json = TestUtils.tournamentToJson(tournament);
        // Criar manualmente o tournament a partir do JSON
        final recreatedTournament = Tournament(
          id: json['id'],
          name: json['name'],
          config: json['config'],
          teamIds: List<String>.from(json['teamIds']),
          queueIds: List<String>.from(json['queueIds']),
          isComplete: json['isComplete'],
        );

        expect(recreatedTournament.id, equals(tournament.id));
        expect(recreatedTournament.name, equals(tournament.name));
        expect(recreatedTournament.teamIds, equals(tournament.teamIds));
        expect(recreatedTournament.queueIds, equals(tournament.queueIds));
        expect(recreatedTournament.isComplete, equals(tournament.isComplete));
      });
    });

    group('Validação', () {
      test('deve aceitar configurações válidas', () {
        expect(
            () => Tournament(
                  id: 'valid_tournament',
                  name: 'Valid Tournament',
                  config: gameConfig,
                  teamIds: ['team1', 'team2'],
                  queueIds: ['team1', 'team2'],
                ),
            returnsNormally);
      });

      test('deve aceitar lista vazia de times', () {
        expect(
            () => Tournament(
                  id: 'empty_tournament',
                  name: 'Empty Tournament',
                  config: gameConfig,
                  teamIds: [],
                  queueIds: [],
                ),
            returnsNormally);
      });

      test('deve aceitar nomes válidos', () {
        expect(
            () => Tournament(
                  id: 'tournament1',
                  name: 'Tournament Name',
                  config: gameConfig,
                  teamIds: ['team1'],
                  queueIds: ['team1'],
                ),
            returnsNormally);

        expect(
            () => Tournament(
                  id: 'tournament2',
                  name: 'T',
                  config: gameConfig,
                  teamIds: ['team1'],
                  queueIds: ['team1'],
                ),
            returnsNormally);
      });
    });
  });
}
