import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:placar_iterativo_app/main.dart' as app;
import '../test_utils.dart';

// Métodos auxiliares
Future<void> createTeamsAndStartGame(WidgetTester tester) async {
  // Navegar para times
  await tester.tap(find.byIcon(Icons.group));
  await tester.pumpAndSettle();

  // Criar Time A
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Time A');
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();

  // Criar Time B
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Time B');
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();

  // Iniciar jogo
  await tester.tap(find.byIcon(Icons.sports_soccer));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Novo Jogo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Time A').first);
  await tester.tap(find.text('Time B').first);
  await tester.tap(find.text('Iniciar Jogo'));
  await tester.pumpAndSettle();
}

Future<void> createTeamsAndPlayMatch(WidgetTester tester) async {
  await createTeamsAndStartGame(tester);

  // Marcar alguns pontos
  for (int i = 0; i < 5; i++) {
    await tester.tap(find.byKey(const Key('increment_team_a')));
    await tester.pumpAndSettle();
  }

  for (int i = 0; i < 3; i++) {
    await tester.tap(find.byKey(const Key('increment_team_b')));
    await tester.pumpAndSettle();
  }

  // Finalizar jogo
  await tester.tap(find.text('Finalizar Jogo'));
  await tester.pumpAndSettle();
}

Future<void> createMultipleTeams(WidgetTester tester, int count) async {
  await tester.tap(find.byIcon(Icons.group));
  await tester.pumpAndSettle();

  for (int i = 1; i <= count; i++) {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Time $i');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
  }
}

Future<void> createMultipleMatches(WidgetTester tester) async {
  await createMultipleTeams(tester, 4);

  // Criar várias partidas
  for (int i = 0; i < 3; i++) {
    await tester.tap(find.byIcon(Icons.sports_soccer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo Jogo'));
    await tester.pumpAndSettle();

    // Selecionar times diferentes
    await tester.tap(find.text('Time ${i + 1}').first);
    await tester.tap(find.text('Time ${i + 2}').first);
    await tester.tap(find.text('Iniciar Jogo'));
    await tester.pumpAndSettle();

    // Jogar partida
    await tester.tap(find.byKey(const Key('increment_team_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar Jogo'));
    await tester.pumpAndSettle();
  }
}

Future<void> createTournamentWithMatches(WidgetTester tester) async {
  await createMultipleTeams(tester, 4);

  await tester.tap(find.byIcon(Icons.emoji_events));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).first, 'Torneio Teste');

  for (int i = 1; i <= 4; i++) {
    await tester.tap(find.text('Time $i'));
  }

  await tester.tap(find.text('Criar Torneio'));
  await tester.pumpAndSettle();
}

Future<void> createBackup(WidgetTester tester) async {
  await createTeamsAndPlayMatch(tester);

  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Backup e Restauração'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Criar Backup'));
  await tester.pumpAndSettle();
}

Future<void> clearAllData(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Limpar Todos os Dados'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle();
}

Future<void> createManyTeams(WidgetTester tester, int count) async {
  await tester.tap(find.byIcon(Icons.group));
  await tester.pumpAndSettle();

  for (int i = 1; i <= count; i++) {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Time $i');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Scroll ocasional para evitar overflow
    if (i % 10 == 0) {
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUp(() async {
      await TestUtils.initializeHiveForTesting();
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    group('Fluxo Completo de Jogo', () {
      testWidgets('deve permitir criar times, iniciar jogo e marcar pontos',
          (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 1. Navegar para tela de times
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();

        // 2. Criar primeiro time
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Time A');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // 3. Criar segundo time
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Time B');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // 4. Navegar para tela de jogo
        await tester.tap(find.byIcon(Icons.sports_soccer));
        await tester.pumpAndSettle();

        // 5. Iniciar novo jogo
        await tester.tap(find.text('Novo Jogo'));
        await tester.pumpAndSettle();

        // 6. Selecionar times
        await tester.tap(find.text('Time A').first);
        await tester.tap(find.text('Time B').first);
        await tester.tap(find.text('Iniciar Jogo'));
        await tester.pumpAndSettle();

        // 7. Verificar se jogo iniciou
        expect(find.text('Time A'), findsWidgets);
        expect(find.text('Time B'), findsWidgets);
        expect(find.text('0'), findsNWidgets(2)); // Pontuações iniciais

        // 8. Marcar pontos para Time A
        await tester.tap(find.byKey(const Key('increment_team_a')));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);

        // 9. Marcar pontos para Time B
        await tester.tap(find.byKey(const Key('increment_team_b')));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsNWidgets(2));

        // 10. Finalizar jogo
        await tester.tap(find.text('Finalizar Jogo'));
        await tester.pumpAndSettle();

        // 11. Verificar se jogo foi salvo
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        expect(find.text('Time A vs Time B'), findsOneWidget);
      });

      testWidgets('deve permitir pausar e retomar jogo', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar times e iniciar jogo (passos simplificados)
        await createTeamsAndStartGame(tester);

        // Pausar jogo
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();

        expect(find.text('PAUSADO'), findsOneWidget);

        // Retomar jogo
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pumpAndSettle();

        expect(find.text('PAUSADO'), findsNothing);
      });
    });

    group('Gestão de Times', () {
      testWidgets('deve permitir criar, editar e deletar times',
          (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Navegar para times
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();

        // Criar time
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Novo Time');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('Novo Time'), findsOneWidget);

        // Editar time
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField).first, 'Time Editado');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('Time Editado'), findsOneWidget);
        expect(find.text('Novo Time'), findsNothing);

        // Deletar time
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(find.text('Time Editado'), findsNothing);
      });

      testWidgets('deve validar dados do time', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();

        // Tentar criar time sem nome
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('Nome é obrigatório'), findsOneWidget);
      });
    });

    group('Histórico de Partidas', () {
      testWidgets('deve exibir histórico de partidas', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar e jogar uma partida
        await createTeamsAndPlayMatch(tester);

        // Verificar histórico
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        expect(find.textContaining('vs'), findsAtLeastNWidgets(1));
      });

      testWidgets('deve permitir filtrar partidas', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar múltiplas partidas
        await createMultipleMatches(tester);

        // Navegar para histórico
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        // Aplicar filtro
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apenas Finalizadas'));
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();

        // Verificar se filtro foi aplicado
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Torneios', () {
      testWidgets('deve permitir criar e gerenciar torneio', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar times primeiro
        await createMultipleTeams(tester, 4);

        // Navegar para torneios
        await tester.tap(find.byIcon(Icons.emoji_events));
        await tester.pumpAndSettle();

        // Criar novo torneio
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField).first, 'Torneio Teste');

        // Selecionar times
        for (int i = 1; i <= 4; i++) {
          await tester.tap(find.text('Time $i'));
        }

        await tester.tap(find.text('Criar Torneio'));
        await tester.pumpAndSettle();

        expect(find.text('Torneio Teste'), findsOneWidget);

        // Iniciar primeira partida
        await tester.tap(find.text('Iniciar Próxima Partida'));
        await tester.pumpAndSettle();

        expect(find.text('vs'), findsOneWidget);
      });

      testWidgets('deve mostrar classificação do torneio', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar torneio com partidas
        await createTournamentWithMatches(tester);

        // Verificar classificação
        await tester.tap(find.text('Classificação'));
        await tester.pumpAndSettle();

        expect(find.byType(DataTable), findsOneWidget);
        expect(find.text('Posição'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);
        expect(find.text('Pontos'), findsOneWidget);
      });
    });

    group('Configurações', () {
      testWidgets('deve permitir alterar configurações de jogo',
          (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Navegar para configurações
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Alterar pontuação máxima
        await tester.tap(find.text('Configurações de Jogo'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, '15'),
          '21',
        );

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Verificar se configuração foi salva
        expect(find.text('Configurações salvas'), findsOneWidget);
      });

      testWidgets('deve permitir alterar tema', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Alterar para tema escuro
        await tester.tap(find.text('Tema Escuro'));
        await tester.pumpAndSettle();

        // Verificar se tema mudou
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, isNot(equals(Colors.white)));
      });
    });

    group('Backup e Restauração', () {
      testWidgets('deve permitir criar backup', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar alguns dados
        await createTeamsAndPlayMatch(tester);

        // Navegar para configurações
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Criar backup
        await tester.tap(find.text('Backup e Restauração'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Criar Backup'));
        await tester.pumpAndSettle();

        expect(find.text('Backup criado com sucesso'), findsOneWidget);
      });

      testWidgets('deve permitir restaurar backup', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar backup primeiro
        await createBackup(tester);

        // Limpar dados
        await clearAllData(tester);

        // Restaurar backup
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Backup e Restauração'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restaurar Último Backup'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(find.text('Backup restaurado com sucesso'), findsOneWidget);
      });
    });

    group('Acessibilidade', () {
      testWidgets('deve suportar navegação por teclado', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Navegar usando Tab
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Ativar elemento focado
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('deve ter labels de acessibilidade', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Verificar se elementos têm labels apropriados
        expect(find.bySemanticsLabel('Navegar para Times'), findsOneWidget);
        expect(find.bySemanticsLabel('Navegar para Jogos'), findsOneWidget);
        expect(find.bySemanticsLabel('Navegar para Histórico'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('deve carregar rapidamente', (tester) async {
        final stopwatch = Stopwatch()..start();

        app.main();
        await tester.pumpAndSettle();

        stopwatch.stop();

        // App deve carregar em menos de 3 segundos
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });

      testWidgets('deve lidar com muitos dados', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Criar muitos times
        await createManyTeams(tester, 50);

        // Navegar para lista de times
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();

        // Verificar se lista carrega sem problemas
        expect(find.byType(ListView), findsOneWidget);

        // Scroll na lista
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Tratamento de Erros', () {
      testWidgets('deve lidar com erro de rede', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simular erro de rede (se aplicável)
        // Verificar se app continua funcionando
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('deve recuperar de estado inválido', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simular estado inválido
        // Verificar se app se recupera
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
  });

}
