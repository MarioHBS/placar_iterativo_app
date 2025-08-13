import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placar_iterativo_app/models/team.dart';
import '../test_utils.dart';

void main() {
  group('Team Model Tests', () {
    late Team team;

    setUp(() {
      team = TestUtils.createTestTeam(
        id: 'test_team_1',
        name: 'Test Team',
        members: ['Player 1', 'Player 2'],
        color: Colors.blue,
        wins: 5,
        losses: 3,
      );
    });

    group('Construtor e Propriedades', () {
      test('deve criar um team com propriedades corretas', () {
        expect(team.id, equals('test_team_1'));
        expect(team.name, equals('Test Team'));
        expect(team.members, equals(['Player 1', 'Player 2']));
        expect(team.color, equals(Colors.blue));
        expect(team.wins, equals(5));
        expect(team.losses, equals(3));
        expect(team.consecutiveWins, equals(0));
        expect(team.isWaiting, equals(false));
        expect(team.tournamentConsecutiveWins, isEmpty);
      });

      test('deve criar um team com valores padrão', () {
        final defaultTeam = Team(
          id: 'default_team',
          name: 'Default Team',
          color: Colors.red,
        );

        expect(defaultTeam.members, isEmpty);
        expect(defaultTeam.emoji, isNull);
        expect(defaultTeam.imagePath, isNull);
        expect(defaultTeam.wins, equals(0));
        expect(defaultTeam.losses, equals(0));
        expect(defaultTeam.consecutiveWins, equals(0));
        expect(defaultTeam.isWaiting, equals(false));
        expect(defaultTeam.tournamentConsecutiveWins, isEmpty);
      });
    });

    group('Métodos de Estatísticas', () {
      test('winRate deve calcular a taxa de vitórias corretamente', () {
        expect(team.winRate, closeTo(62.5, 0.001)); // 5/(5+3) = 0.625 = 62.5%
      });

      test('winRate deve retornar 0 quando não há jogos', () {
        final newTeam = TestUtils.createTestTeam(wins: 0, losses: 0);
        expect(newTeam.winRate, equals(0.0));
      });

      test('winRate deve retornar 100 quando só há vitórias', () {
        final winningTeam = TestUtils.createTestTeam(wins: 10, losses: 0);
        expect(winningTeam.winRate, equals(100.0));
      });

      test('totalGames deve retornar o total de jogos', () {
        expect(team.totalGames, equals(8)); // 5 + 3
      });

      test('totalGames deve retornar 0 quando não há jogos', () {
        final newTeam = TestUtils.createTestTeam(wins: 0, losses: 0);
        expect(newTeam.totalGames, equals(0));
      });
    });

    group('Métodos de Manipulação', () {
      test('addWin deve incrementar vitórias e vitórias consecutivas', () {
        final initialWins = team.wins;
        final initialConsecutive = team.consecutiveWins;
        
        team.addWin();
        
        expect(team.wins, equals(initialWins + 1));
        expect(team.consecutiveWins, equals(initialConsecutive + 1));
      });

      test('addLoss deve incrementar derrotas e zerar vitórias consecutivas', () {
        team.consecutiveWins = 3; // Definir algumas vitórias consecutivas
        final initialLosses = team.losses;
        
        team.addLoss();
        
        expect(team.losses, equals(initialLosses + 1));
        expect(team.consecutiveWins, equals(0));
      });

      test('resetStats deve zerar todas as estatísticas', () {
        team.resetStats();
        
        expect(team.wins, equals(0));
        expect(team.losses, equals(0));
        expect(team.consecutiveWins, equals(0));
        expect(team.isWaiting, equals(false));
        expect(team.tournamentConsecutiveWins, isEmpty);
      });
    });

    group('Métodos de Torneio', () {
      test('getTournamentConsecutiveWins deve retornar vitórias consecutivas do torneio', () {
        const tournamentId = 'tournament_1';
        // Adiciona vitórias usando o método apropriado
        for (int i = 0; i < 5; i++) {
          team.addWin(tournamentId);
        }
        
        expect(team.getTournamentConsecutiveWins(tournamentId), equals(5));
      });

      test('getTournamentConsecutiveWins deve retornar 0 para torneio não encontrado', () {
        expect(team.getTournamentConsecutiveWins('nonexistent'), equals(0));
      });

      test('addWin deve incrementar vitórias consecutivas do torneio', () {
        const tournamentId = 'tournament1';
        
        team.addWin(tournamentId);
        expect(team.getTournamentConsecutiveWins(tournamentId), equals(1));
        
        team.addWin(tournamentId);
        expect(team.getTournamentConsecutiveWins(tournamentId), equals(2));
      });

      test('resetTournamentConsecutiveWins deve zerar vitórias consecutivas do torneio', () {
        const tournamentId = 'tournament_1';
        // Adiciona algumas vitórias primeiro
        for (int i = 0; i < 5; i++) {
          team.addWin(tournamentId);
        }
        
        expect(team.getTournamentConsecutiveWins(tournamentId), equals(5));
        
        team.resetTournamentConsecutiveWins(tournamentId);
        expect(team.getTournamentConsecutiveWins(tournamentId), equals(0));
      });
    });

    group('Métodos de Comparação', () {
      test('winRate deve calcular porcentagem corretamente', () {
        final teamA = TestUtils.createTestTeam(wins: 8, losses: 2); // 80%
        final teamB = TestUtils.createTestTeam(wins: 6, losses: 4); // 60%
        
        expect(teamA.winRate, equals(80.0));
        expect(teamB.winRate, equals(60.0));
        expect(teamA.winRate, greaterThan(teamB.winRate));
      });
      
      test('totalGames deve somar vitórias e derrotas', () {
        final teamA = TestUtils.createTestTeam(wins: 6, losses: 4);
        final teamB = TestUtils.createTestTeam(wins: 3, losses: 2);
        
        expect(teamA.totalGames, equals(10));
        expect(teamB.totalGames, equals(5));
      });
      
      test('winRate deve retornar 0 quando não há jogos', () {
        final team = TestUtils.createTestTeam(wins: 0, losses: 0);
        
        expect(team.winRate, equals(0.0));
        expect(team.totalGames, equals(0));
      });
    });

    group('Métodos de Cópia', () {
      test('copyWith deve criar uma cópia com propriedades alteradas', () {
        final copiedTeam = team.copyWith(
          name: 'New Name',
          wins: 10,
        );
        
        expect(copiedTeam.id, equals(team.id));
        expect(copiedTeam.name, equals('New Name'));
        expect(copiedTeam.wins, equals(10));
        expect(copiedTeam.losses, equals(team.losses));
        expect(copiedTeam.color, equals(team.color));
      });

      test('copyWith deve manter propriedades originais quando não especificadas', () {
        final copiedTeam = team.copyWith();
        
        expect(copiedTeam.id, equals(team.id));
        expect(copiedTeam.name, equals(team.name));
        expect(copiedTeam.wins, equals(team.wins));
        expect(copiedTeam.losses, equals(team.losses));
        expect(copiedTeam.color, equals(team.color));
      });
    });

    group('Serialização', () {
      test('toJson deve converter team para Map', () {
        final json = TestUtils.teamToJson(team);
        
        expect(json['id'], equals(team.id));
        expect(json['name'], equals(team.name));
        expect(json['wins'], equals(team.wins));
        expect(json['losses'], equals(team.losses));
        expect(json['color'], equals(team.color.value));
      });

      test('fromJson deve criar team a partir de Map', () {
        final json = TestUtils.teamToJson(team);
        // Como não há método fromJson, vamos testar a criação manual
        final recreatedTeam = Team(
          id: json['id'],
          name: json['name'],
          color: Color(json['color']),
          wins: json['wins'],
          losses: json['losses'],
          members: List<String>.from(json['members']),
          consecutiveWins: json['consecutiveWins'],
          isWaiting: json['isWaiting'],
          tournamentConsecutiveWins: Map<String, int>.from(json['tournamentConsecutiveWins']),
          emoji: json['emoji'],
          imagePath: json['imagePath'],
        );
        
        expect(recreatedTeam.id, equals(team.id));
        expect(recreatedTeam.name, equals(team.name));
        expect(recreatedTeam.wins, equals(team.wins));
        expect(recreatedTeam.losses, equals(team.losses));
        expect(recreatedTeam.color.value, equals(team.color.value));
      });
    });

    group('Validação', () {
      test('deve aceitar nomes válidos', () {
        expect(() => Team(id: '1', name: 'Valid Name', color: Colors.red), returnsNormally);
        expect(() => Team(id: '2', name: 'Team 123', color: Colors.blue), returnsNormally);
        expect(() => Team(id: '3', name: 'A', color: Colors.green), returnsNormally);
      });

      test('deve aceitar cores válidas', () {
        expect(() => Team(id: '1', name: 'Team', color: Colors.red), returnsNormally);
        expect(() => Team(id: '2', name: 'Team', color: const Color(0xFF123456)), returnsNormally);
      });

      test('deve aceitar listas de membros válidas', () {
        expect(() => Team(id: '1', name: 'Team', color: Colors.red, members: []), returnsNormally);
        expect(() => Team(id: '2', name: 'Team', color: Colors.red, members: ['Player 1']), returnsNormally);
        expect(() => Team(id: '3', name: 'Team', color: Colors.red, members: ['P1', 'P2', 'P3']), returnsNormally);
      });
    });
  });
}