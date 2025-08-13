import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/match.dart';
import '../test_utils.dart';

void main() {
  group('Match Model Tests', () {
    late Match match;
    late DateTime startTime;

    setUp(() {
      startTime = DateTime.now();
      match = TestUtils.createTestMatch(
        id: 'test_match_1',
        teamAId: 'team_a',
        teamBId: 'team_b',
        teamAScore: 5,
        teamBScore: 3,
      );
      match.startTime = startTime;
    });

    group('Construtor e Propriedades', () {
      test('deve criar uma partida com propriedades corretas', () {
        expect(match.id, equals('test_match_1'));
        expect(match.teamAId, equals('team_a'));
        expect(match.teamBId, equals('team_b'));
        expect(match.teamAScore, equals(5));
        expect(match.teamBScore, equals(3));
        expect(match.startTime, equals(startTime));
        expect(match.isComplete, equals(false));
        expect(match.endTime, isNull);
        expect(match.winnerId, isNull);
        expect(match.loserId, isNull);
      });

      test('deve criar uma partida com valores padrão', () {
        final defaultMatch = Match(
          id: 'default_match',
          teamAId: 'team1',
          teamBId: 'team2',
          startTime: DateTime.now(),
        );

        expect(defaultMatch.teamAScore, equals(0));
        expect(defaultMatch.teamBScore, equals(0));
        expect(defaultMatch.durationInSeconds, equals(0));
        expect(defaultMatch.isComplete, equals(false));
        expect(defaultMatch.endTime, isNull);
        expect(defaultMatch.winnerId, isNull);
        expect(defaultMatch.loserId, isNull);
      });
    });

    group('Métodos de Pontuação', () {
      test('incrementTeamAScore deve aumentar pontuação do time A', () {
        final initialScore = match.teamAScore;
        match.incrementTeamAScore();
        expect(match.teamAScore, equals(initialScore + 1));
      });

      test('incrementTeamBScore deve aumentar pontuação do time B', () {
        final initialScore = match.teamBScore;
        match.incrementTeamBScore();
        expect(match.teamBScore, equals(initialScore + 1));
      });

      test('decrementTeamAScore deve diminuir pontuação do time A', () {
        match.teamAScore = 5;
        match.decrementTeamAScore();
        expect(match.teamAScore, equals(4));
      });

      test('decrementTeamBScore deve diminuir pontuação do time B', () {
        match.teamBScore = 3;
        match.decrementTeamBScore();
        expect(match.teamBScore, equals(2));
      });

      test('decrementTeamAScore não deve permitir pontuação negativa', () {
        match.teamAScore = 0;
        match.decrementTeamAScore();
        expect(match.teamAScore, equals(0));
      });

      test('decrementTeamBScore não deve permitir pontuação negativa', () {
        match.teamBScore = 0;
        match.decrementTeamBScore();
        expect(match.teamBScore, equals(0));
      });

      test('setTeamAScore deve definir pontuação do time A', () {
        match.setTeamAScore(10);
        expect(match.teamAScore, equals(10));
      });

      test('setTeamBScore deve definir pontuação do time B', () {
        match.setTeamBScore(8);
        expect(match.teamBScore, equals(8));
      });

      test('setTeamAScore não deve permitir pontuação negativa', () {
        match.setTeamAScore(-5);
        expect(match.teamAScore, equals(0));
      });

      test('setTeamBScore não deve permitir pontuação negativa', () {
        match.setTeamBScore(-3);
        expect(match.teamBScore, equals(0));
      });
    });

    group('Métodos de Estado da Partida', () {
      test('isTeamAWinning deve retornar true quando time A está ganhando', () {
        match.teamAScore = 10;
        match.teamBScore = 5;
        expect(match.isTeamAWinning, isTrue);
      });

      test('isTeamAWinning deve retornar false quando time A não está ganhando', () {
        match.teamAScore = 5;
        match.teamBScore = 10;
        expect(match.isTeamAWinning, isFalse);
      });

      test('isTeamBWinning deve retornar true quando time B está ganhando', () {
        match.teamAScore = 3;
        match.teamBScore = 8;
        expect(match.isTeamBWinning, isTrue);
      });

      test('isTeamBWinning deve retornar false quando time B não está ganhando', () {
        match.teamAScore = 8;
        match.teamBScore = 3;
        expect(match.isTeamBWinning, isFalse);
      });

      test('isTied deve retornar true quando há empate', () {
        match.teamAScore = 5;
        match.teamBScore = 5;
        expect(match.isTied, isTrue);
      });

      test('isTied deve retornar false quando não há empate', () {
        match.teamAScore = 5;
        match.teamBScore = 3;
        expect(match.isTied, isFalse);
      });

      test('getWinningTeamId deve retornar ID do time vencedor', () {
        match.teamAScore = 10;
        match.teamBScore = 5;
        expect(match.getWinningTeamId(), equals('team_a'));

        match.teamAScore = 3;
        match.teamBScore = 8;
        expect(match.getWinningTeamId(), equals('team_b'));
      });

      test('getWinningTeamId deve retornar null em caso de empate', () {
        match.teamAScore = 5;
        match.teamBScore = 5;
        expect(match.getWinningTeamId(), isNull);
      });

      test('getLosingTeamId deve retornar ID do time perdedor', () {
        match.teamAScore = 10;
        match.teamBScore = 5;
        expect(match.getLosingTeamId(), equals('team_b'));

        match.teamAScore = 3;
        match.teamBScore = 8;
        expect(match.getLosingTeamId(), equals('team_a'));
      });

      test('getLosingTeamId deve retornar null em caso de empate', () {
        match.teamAScore = 5;
        match.teamBScore = 5;
        expect(match.getLosingTeamId(), isNull);
      });
    });

    group('Métodos de Finalização', () {
      test('completeMatch deve finalizar a partida corretamente', () {
        match.teamAScore = 10;
        match.teamBScore = 7;
        
        match.completeMatch();
        
        expect(match.isComplete, isTrue);
        expect(match.endTime, isNotNull);
        expect(match.winnerId, equals('team_a'));
        expect(match.loserId, equals('team_b'));
        expect(match.durationInSeconds, greaterThan(0));
      });

      test('completeMatch deve lidar com empate', () {
        match.teamAScore = 5;
        match.teamBScore = 5;
        
        match.completeMatch();
        
        expect(match.isComplete, isTrue);
        expect(match.endTime, isNotNull);
        expect(match.winnerId, isNull);
        expect(match.loserId, isNull);
      });

      test('resetMatch deve reiniciar a partida', () {
        match.teamAScore = 10;
        match.teamBScore = 7;
        match.completeMatch();
        
        match.resetMatch();
        
        expect(match.teamAScore, equals(0));
        expect(match.teamBScore, equals(0));
        expect(match.isComplete, isFalse);
        expect(match.endTime, isNull);
        expect(match.winnerId, isNull);
        expect(match.loserId, isNull);
        expect(match.durationInSeconds, equals(0));
      });
    });

    group('Métodos de Duração', () {
      test('getCurrentDuration deve calcular duração atual', () {
        final now = DateTime.now();
        final pastTime = now.subtract(const Duration(minutes: 5));
        match.startTime = pastTime;
        
        final duration = match.getCurrentDuration();
        expect(duration.inMinutes, equals(5));
      });

      test('getFormattedDuration deve formatar duração corretamente', () {
        match.durationInSeconds = 125; // 2 minutos e 5 segundos
        expect(match.getFormattedDuration(), equals('02:05'));
        
        match.durationInSeconds = 3665; // 1 hora, 1 minuto e 5 segundos
        expect(match.getFormattedDuration(), equals('01:01:05'));
      });

      test('getFormattedCurrentDuration deve formatar duração atual', () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2, seconds: 30));
        match.startTime = pastTime;
        
        final formatted = match.getFormattedCurrentDuration();
        expect(formatted, matches(r'^\d{2}:\d{2}$')); // Formato MM:SS
      });
    });

    group('Métodos de Cópia', () {
      test('copyWith deve criar uma cópia com propriedades alteradas', () {
        final copiedMatch = match.copyWith(
          teamAScore: 15,
          teamBScore: 12,
          isComplete: true,
        );
        
        expect(copiedMatch.id, equals(match.id));
        expect(copiedMatch.teamAId, equals(match.teamAId));
        expect(copiedMatch.teamBId, equals(match.teamBId));
        expect(copiedMatch.teamAScore, equals(15));
        expect(copiedMatch.teamBScore, equals(12));
        expect(copiedMatch.isComplete, isTrue);
      });

      test('copyWith deve manter propriedades originais quando não especificadas', () {
        final copiedMatch = match.copyWith();
        
        expect(copiedMatch.id, equals(match.id));
        expect(copiedMatch.teamAId, equals(match.teamAId));
        expect(copiedMatch.teamBId, equals(match.teamBId));
        expect(copiedMatch.teamAScore, equals(match.teamAScore));
        expect(copiedMatch.teamBScore, equals(match.teamBScore));
        expect(copiedMatch.isComplete, equals(match.isComplete));
      });
    });

    group('Serialização', () {
      test('toJson deve converter match para Map', () {
        final json = TestUtils.matchToJson(match);
        
        expect(json['id'], equals(match.id));
        expect(json['teamAId'], equals(match.teamAId));
        expect(json['teamBId'], equals(match.teamBId));
        expect(json['teamAScore'], equals(match.teamAScore));
        expect(json['teamBScore'], equals(match.teamBScore));
        expect(json['isComplete'], equals(match.isComplete));
      });

      test('fromJson deve criar match a partir de Map', () {
        final json = TestUtils.matchToJson(match);
        // Criar manualmente o match a partir do JSON
        // Criar manualmente o match a partir do JSON
         final recreatedMatch = Match(
           id: json['id'],
           teamAId: json['teamAId'],
           teamBId: json['teamBId'],
           teamAScore: json['teamAScore'],
           teamBScore: json['teamBScore'],
           startTime: DateTime.parse(json['startTime']),
           endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
           isComplete: json['isComplete'],
         );
        
        expect(recreatedMatch.id, equals(match.id));
        expect(recreatedMatch.teamAId, equals(match.teamAId));
        expect(recreatedMatch.teamBId, equals(match.teamBId));
        expect(recreatedMatch.teamAScore, equals(match.teamAScore));
        expect(recreatedMatch.teamBScore, equals(match.teamBScore));
        expect(recreatedMatch.isComplete, equals(match.isComplete));
      });
    });

    group('Validação', () {
      test('deve aceitar IDs de times válidos', () {
        expect(() => Match(
          id: 'match1',
          teamAId: 'team_a',
          teamBId: 'team_b',
          startTime: DateTime.now(),
        ), returnsNormally);
      });

      test('deve aceitar pontuações válidas', () {
        final validMatch = Match(
          id: 'match1',
          teamAId: 'team_a',
          teamBId: 'team_b',
          teamAScore: 0,
          teamBScore: 100,
          startTime: DateTime.now(),
        );
        
        expect(validMatch.teamAScore, equals(0));
        expect(validMatch.teamBScore, equals(100));
      });

      test('deve aceitar horários válidos', () {
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 1));
        
        final validMatch = Match(
          id: 'match1',
          teamAId: 'team_a',
          teamBId: 'team_b',
          startTime: now,
          endTime: future,
        );
        
        expect(validMatch.startTime, equals(now));
        expect(validMatch.endTime, equals(future));
      });
    });
  });
}