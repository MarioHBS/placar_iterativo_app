import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import '../test_utils.dart';

void main() {
  group('GameConfig Model Tests', () {
    late GameConfig gameConfig;

    setUp(() {
      gameConfig = TestUtils.createTestGameConfig(
        id: 'test_config_1',
        gameMode: GameMode.tournament,
        endCondition: EndCondition.score,
      );
    });

    group('Construtor e Propriedades', () {
      test('deve criar uma configuração com propriedades corretas', () {
        expect(gameConfig.id, equals('test_config_1'));
        expect(gameConfig.gameMode, equals(GameMode.tournament));
        expect(gameConfig.endCondition, equals(EndCondition.score));
      });

      test('deve criar uma configuração com valores padrão', () {
        final defaultConfig = GameConfig(
          id: 'default_config',
          gameMode: GameMode.tournament,
        );

        expect(defaultConfig.endCondition, isNull);
        expect(defaultConfig.maxScore, isNull);
        expect(defaultConfig.maxTime, isNull);
        expect(defaultConfig.tournamentEndCondition, isNull);
      });
    });

    group('Enums', () {
      test('GameMode deve ter valores corretos', () {
        expect(GameMode.values, contains(GameMode.tournament));
      });

      test('EndCondition deve ter todos os valores esperados', () {
        expect(EndCondition.values, containsAll([
          EndCondition.none,
          EndCondition.time,
          EndCondition.score,
          EndCondition.both,
        ]));
      });

      test('TournamentEndCondition deve ter todos os valores esperados', () {
        expect(TournamentEndCondition.values, containsAll([
          TournamentEndCondition.none,
          TournamentEndCondition.firstToWins,
          TournamentEndCondition.mostWinsInRounds,
          TournamentEndCondition.pointsSystem,
          TournamentEndCondition.totalDuration,
          TournamentEndCondition.specificDeadline,
          TournamentEndCondition.maxMatches,
        ]));
      });
    });

    group('Métodos de Validação', () {
      test('isValidConfig deve retornar true para configuração válida', () {
        final validConfig = GameConfig(
          id: 'valid',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 10,
        );
        
        expect(validConfig.isValidConfig(), isTrue);
      });

      test('isValidConfig deve retornar false para configuração inválida', () {
        final invalidConfig = GameConfig(
          id: 'invalid',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          // maxScore não definido quando endCondition é score
        );
        
        expect(invalidConfig.isValidConfig(), isFalse);
      });

      test('hasTimeLimit deve retornar true quando há limite de tempo', () {
        final configWithTime = GameConfig(
          id: 'time_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.time,
          maxTime: const Duration(minutes: 30),
        );
        
        expect(configWithTime.hasTimeLimit(), isTrue);
      });

      test('hasTimeLimit deve retornar false quando não há limite de tempo', () {
        final configWithoutTime = GameConfig(
          id: 'no_time_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 10,
        );
        
        expect(configWithoutTime.hasTimeLimit(), isFalse);
      });

      test('hasScoreLimit deve retornar true quando há limite de pontuação', () {
        final configWithScore = GameConfig(
          id: 'score_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 15,
        );
        
        expect(configWithScore.hasScoreLimit(), isTrue);
      });

      test('hasScoreLimit deve retornar false quando não há limite de pontuação', () {
        final configWithoutScore = GameConfig(
          id: 'no_score_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.time,
          maxTime: const Duration(minutes: 20),
        );
        
        expect(configWithoutScore.hasScoreLimit(), isFalse);
      });
    });

    group('Métodos de Verificação de Fim de Jogo', () {
      test('isGameComplete deve retornar true quando pontuação máxima é atingida', () {
        final config = GameConfig(
          id: 'score_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 10,
        );
        
        expect(config.isGameComplete(teamAScore: 10, teamBScore: 5), isTrue);
        expect(config.isGameComplete(teamAScore: 5, teamBScore: 10), isTrue);
        expect(config.isGameComplete(teamAScore: 8, teamBScore: 7), isFalse);
      });

      test('isGameComplete deve retornar true quando tempo máximo é atingido', () {
        final config = GameConfig(
          id: 'time_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.time,
          maxTime: const Duration(minutes: 30),
        );
        
        expect(config.isGameComplete(duration: const Duration(minutes: 30)), isTrue);
        expect(config.isGameComplete(duration: const Duration(minutes: 35)), isTrue);
        expect(config.isGameComplete(duration: const Duration(minutes: 25)), isFalse);
      });

      test('isGameComplete deve verificar ambas condições quando endCondition é both', () {
        final config = GameConfig(
          id: 'both_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.both,
          maxScore: 10,
          maxTime: const Duration(minutes: 30),
        );
        
        // Deve retornar true se qualquer condição for atendida
        expect(config.isGameComplete(
          teamAScore: 10,
          teamBScore: 5,
          duration: const Duration(minutes: 20),
        ), isTrue);
        
        expect(config.isGameComplete(
          teamAScore: 8,
          teamBScore: 7,
          duration: const Duration(minutes: 30),
        ), isTrue);
        
        expect(config.isGameComplete(
          teamAScore: 8,
          teamBScore: 7,
          duration: const Duration(minutes: 20),
        ), isFalse);
      });

      test('isGameComplete deve retornar false quando endCondition é none', () {
        final config = GameConfig(
          id: 'none_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.none,
        );
        
        expect(config.isGameComplete(
          teamAScore: 100,
          teamBScore: 50,
          duration: const Duration(hours: 5),
        ), isFalse);
      });
    });

    group('Métodos de Torneio', () {
      test('isTournamentComplete deve verificar condição firstToWins', () {
        final config = GameConfig(
          id: 'tournament_config',
          gameMode: GameMode.tournament,
          tournamentEndCondition: TournamentEndCondition.firstToWins,
          firstToWins: 5,
        );
        
        expect(config.isTournamentComplete(matchesPlayed: 10, maxWins: 5), isTrue);
        expect(config.isTournamentComplete(matchesPlayed: 8, maxWins: 4), isFalse);
      });

      test('isTournamentComplete deve verificar condição maxMatches', () {
        final config = GameConfig(
          id: 'tournament_config',
          gameMode: GameMode.tournament,
          tournamentEndCondition: TournamentEndCondition.maxMatches,
          totalMatches: 20,
        );
        
        expect(config.isTournamentComplete(matchesPlayed: 20), isTrue);
        expect(config.isTournamentComplete(matchesPlayed: 25), isTrue);
        expect(config.isTournamentComplete(matchesPlayed: 15), isFalse);
      });

      test('isTournamentComplete deve verificar condição totalDuration', () {
        final config = GameConfig(
          id: 'tournament_config',
          gameMode: GameMode.tournament,
          tournamentEndCondition: TournamentEndCondition.totalDuration,
          tournamentDuration: const Duration(hours: 2),
        );
        
        expect(config.isTournamentComplete(
          tournamentDuration: const Duration(hours: 2, minutes: 30),
        ), isTrue);
        
        expect(config.isTournamentComplete(
          tournamentDuration: const Duration(hours: 1, minutes: 30),
        ), isFalse);
      });

      test('isTournamentComplete deve retornar false para condição none', () {
        final config = GameConfig(
          id: 'tournament_config',
          gameMode: GameMode.tournament,
          tournamentEndCondition: TournamentEndCondition.none,
        );
        
        expect(config.isTournamentComplete(
          matchesPlayed: 100,
          maxWins: 50,
          tournamentDuration: const Duration(days: 1),
        ), isFalse);
      });
    });

    group('Métodos de Cópia', () {
      test('copyWith deve criar uma cópia com propriedades alteradas', () {
        final copiedConfig = gameConfig.copyWith(
          gameMode: GameMode.tournament,
          endCondition: EndCondition.time,
          maxTime: const Duration(minutes: 45),
        );
        
        expect(copiedConfig.id, equals(gameConfig.id));
        expect(copiedConfig.gameMode, equals(GameMode.tournament));
        expect(copiedConfig.endCondition, equals(EndCondition.time));
        expect(copiedConfig.maxTime, equals(const Duration(minutes: 45)));
      });

      test('copyWith deve manter propriedades originais quando não especificadas', () {
        final copiedConfig = gameConfig.copyWith();
        
        expect(copiedConfig.id, equals(gameConfig.id));
        expect(copiedConfig.gameMode, equals(gameConfig.gameMode));
        expect(copiedConfig.endCondition, equals(gameConfig.endCondition));
      });
    });

    group('Serialização', () {
      test('toJson deve converter config para Map', () {
        final config = GameConfig(
          id: 'test_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 15,
          maxTime: const Duration(minutes: 30),
        );
        
        final json = TestUtils.gameConfigToJson(config);
        
        expect(json['id'], equals('test_config'));
        expect(json['gameMode'], equals(GameMode.tournament.index));
        expect(json['endCondition'], equals(EndCondition.score.index));
        expect(json['maxScore'], equals(15));
      });

      test('fromJson deve criar config a partir de Map', () {
        final originalConfig = GameConfig(
          id: 'test_config',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.both,
          maxScore: 20,
          maxTime: const Duration(minutes: 45),
        );
        
        final json = TestUtils.gameConfigToJson(originalConfig);
        final recreatedConfig = TestUtils.gameConfigFromJson(json);
        
        expect(recreatedConfig.id, equals(originalConfig.id));
        expect(recreatedConfig.gameMode, equals(originalConfig.gameMode));
        expect(recreatedConfig.endCondition, equals(originalConfig.endCondition));
        expect(recreatedConfig.maxScore, equals(originalConfig.maxScore));
      });
    });

    group('Métodos de Formatação', () {
      test('getEndConditionDescription deve retornar descrição correta', () {
        final scoreConfig = GameConfig(
          id: 'score',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 10,
        );
        
        expect(scoreConfig.getEndConditionDescription(), contains('10'));
        
        final timeConfig = GameConfig(
          id: 'time',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.time,
          maxTime: const Duration(minutes: 30),
        );
        
        expect(timeConfig.getEndConditionDescription(), contains('30'));
      });

      test('getFormattedMaxTime deve formatar tempo corretamente', () {
        final config = GameConfig(
          id: 'time_config',
          gameMode: GameMode.tournament,
          maxTime: const Duration(hours: 1, minutes: 30, seconds: 45),
        );
        
        expect(config.getFormattedMaxTime(), equals('01:30:45'));
      });

      test('getFormattedMaxTime deve retornar string vazia quando não há tempo', () {
        final config = GameConfig(
          id: 'no_time_config',
          gameMode: GameMode.tournament,
        );
        
        expect(config.getFormattedMaxTime(), equals(''));
      });
    });

    group('Validação', () {
      test('deve aceitar configurações válidas', () {
        expect(() => GameConfig(
          id: 'valid1',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.score,
          maxScore: 10,
        ), returnsNormally);
        
        expect(() => GameConfig(
          id: 'valid2',
          gameMode: GameMode.tournament,
          endCondition: EndCondition.time,
          maxTime: const Duration(minutes: 30),
        ), returnsNormally);
      });

      test('deve aceitar valores nulos opcionais', () {
        expect(() => GameConfig(
          id: 'minimal',
          gameMode: GameMode.tournament,
        ), returnsNormally);
      });
    });
  });
}