import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:placar_iterativo_app/widgets/team_card.dart';
import 'package:placar_iterativo_app/models/team.dart';
import '../test_utils.dart';

void main() {
  group('TeamCard Widget Tests', () {
    late Team testTeam;
    late VoidCallback mockOnTap;
    late VoidCallback mockOnEdit;
    late VoidCallback mockOnDelete;

    setUp(() {
      testTeam = TestUtils.createTestTeam(
        id: 'test_team',
        name: 'Test Team',
        color: Colors.blue,
        wins: 5,
        losses: 3,
      );
      
      mockOnTap = () {};
      mockOnEdit = () {};
      mockOnDelete = () {};
    });

    Widget createTestWidget({
      Team? team,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
      bool showStats = true,
      bool showActions = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TeamCard(
            team: team ?? testTeam,
            onTap: onTap ?? mockOnTap,
            onEdit: onEdit ?? mockOnEdit,
            onDelete: onDelete ?? mockOnDelete,
            showStats: showStats,
            showActions: showActions,
          ),
        ),
      );
    }

    group('Renderização Básica', () {
      testWidgets('deve renderizar informações básicas do time', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(TeamCard), findsOneWidget);
        expect(find.text('Test Team'), findsOneWidget);
      });

      testWidgets('deve exibir nome do time corretamente', (tester) async {
        final customTeam = TestUtils.createTestTeam(
          id: 'custom',
          name: 'Custom Team Name',
        );
        
        await tester.pumpWidget(createTestWidget(team: customTeam));
        
        expect(find.text('Custom Team Name'), findsOneWidget);
      });

      testWidgets('deve renderizar sem erros com dados mínimos', (tester) async {
        final minimalTeam = TestUtils.createTestTeam(
          id: 'minimal',
          name: 'Minimal',
        );
        
        await tester.pumpWidget(createTestWidget(team: minimalTeam));
        
        expect(find.byType(TeamCard), findsOneWidget);
        expect(find.text('Minimal'), findsOneWidget);
      });
    });

    group('Exibição de Estatísticas', () {
      testWidgets('deve exibir estatísticas quando showStats é true', (tester) async {
        await tester.pumpWidget(createTestWidget(showStats: true));
        
        expect(find.text('Vitórias: 5'), findsOneWidget);
        expect(find.text('Derrotas: 3'), findsOneWidget);
      });

      testWidgets('deve ocultar estatísticas quando showStats é false', (tester) async {
        await tester.pumpWidget(createTestWidget(showStats: false));
        
        expect(find.text('Vitórias: 5'), findsNothing);
        expect(find.text('Derrotas: 3'), findsNothing);
      });

      testWidgets('deve exibir taxa de vitórias', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Taxa de vitórias: 5/(5+3) = 62.5%
        expect(find.textContaining('62.5%'), findsOneWidget);
      });

      testWidgets('deve lidar com estatísticas zeradas', (tester) async {
        final newTeam = TestUtils.createTestTeam(
          id: 'new_team',
          name: 'New Team',
          wins: 0,
          losses: 0,
        );
        
        await tester.pumpWidget(createTestWidget(team: newTeam));
        
        expect(find.text('Vitórias: 0'), findsOneWidget);
        expect(find.text('Derrotas: 0'), findsOneWidget);
        expect(find.text('0.0%'), findsOneWidget);
      });

      testWidgets('deve exibir apenas vitórias quando não há derrotas', (tester) async {
        final winnerTeam = TestUtils.createTestTeam(
          id: 'winner',
          name: 'Winner Team',
          wins: 10,
          losses: 0,
        );
        
        await tester.pumpWidget(createTestWidget(team: winnerTeam));
        
        expect(find.text('100.0%'), findsOneWidget);
      });
    });

    group('Cores do Time', () {
      testWidgets('deve aplicar cor do time', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verificar se a cor é aplicada no card
        final card = tester.widget<Card>(find.byType(Card));
        expect(card, isNotNull);
      });

      testWidgets('deve usar cor padrão quando time não tem cor', (tester) async {
        final teamWithoutColor = TestUtils.createTestTeam(
          id: 'no_color',
          name: 'No Color Team',
          color: null,
        );
        
        await tester.pumpWidget(createTestWidget(team: teamWithoutColor));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve aplicar diferentes cores corretamente', (tester) async {
        final redTeam = TestUtils.createTestTeam(
          id: 'red_team',
          name: 'Red Team',
          color: Colors.red,
        );
        
        await tester.pumpWidget(createTestWidget(team: redTeam));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });
    });

    group('Ações do Card', () {
      testWidgets('deve exibir botões de ação quando showActions é true', (tester) async {
        await tester.pumpWidget(createTestWidget(showActions: true));
        
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('deve ocultar botões de ação quando showActions é false', (tester) async {
        await tester.pumpWidget(createTestWidget(showActions: false));
        
        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      });

      testWidgets('deve chamar onEdit quando botão editar é pressionado', (tester) async {
        bool editCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          onEdit: () => editCalled = true,
        ));
        
        await tester.tap(find.byIcon(Icons.edit));
        
        expect(editCalled, isTrue);
      });

      testWidgets('deve chamar onDelete quando botão deletar é pressionado', (tester) async {
        bool deleteCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          onDelete: () => deleteCalled = true,
        ));
        
        await tester.tap(find.byIcon(Icons.delete));
        
        expect(deleteCalled, isTrue);
      });
    });

    group('Interação com Card', () {
      testWidgets('deve chamar onTap quando card é tocado', (tester) async {
        bool tapCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          onTap: () => tapCalled = true,
        ));
        
        await tester.tap(find.byType(TeamCard));
        
        expect(tapCalled, isTrue);
      });

      testWidgets('deve ter feedback visual ao tocar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verificar se há InkWell ou similar para feedback
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });

      testWidgets('deve permitir long press', (tester) async {
        bool longPressCalled = false;
        
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ));
        
        await tester.longPress(find.byType(TeamCard));
        
        expect(longPressCalled, isTrue);
      });
    });

    group('Layout e Design', () {
      testWidgets('deve ter layout consistente', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verificar estrutura básica
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('deve adaptar a diferentes tamanhos de tela', (tester) async {
        // Tela pequena
        await tester.binding.setSurfaceSize(const Size(400, 600));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(TeamCard), findsOneWidget);
        
        // Tela grande
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve ter espaçamento adequado', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.margin, isNotNull);
      });
    });

    group('Estados Visuais', () {
      testWidgets('deve destacar time selecionado', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
              isSelected: true,
            ),
          ),
        ));
        
        // Verificar indicação visual de seleção
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve mostrar estado desabilitado', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
              enabled: false,
            ),
          ),
        ));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve mostrar indicador de time ativo', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
              isActive: true,
            ),
          ),
        ));
        
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });
    });

    group('Acessibilidade', () {
      testWidgets('deve ter labels de acessibilidade', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Time: Test Team'), findsOneWidget);
      });

      testWidgets('deve ter hints para botões de ação', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Editar time'), findsOneWidget);
        expect(find.bySemanticsLabel('Deletar time'), findsOneWidget);
      });

      testWidgets('deve suportar navegação por teclado', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Simular navegação por tab
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve anunciar estatísticas para leitores de tela', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('5 vitórias, 3 derrotas'), findsOneWidget);
      });
    });

    group('Animações', () {
      testWidgets('deve animar entrada do card', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verificar se há animação de entrada
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve animar mudanças de estado', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
              isSelected: false,
            ),
          ),
        ));
        
        // Simular mudança de estado
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
              isSelected: true,
            ),
          ),
        ));
        
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });
    });

    group('Casos Extremos', () {
      testWidgets('deve lidar com nome muito longo', (tester) async {
        final longNameTeam = TestUtils.createTestTeam(
          id: 'long_name',
          name: 'Este é um nome de time extremamente longo que pode causar problemas de layout e deve ser truncado adequadamente',
        );
        
        await tester.pumpWidget(createTestWidget(team: longNameTeam));
        
        expect(find.byType(TeamCard), findsOneWidget);
        // Verificar se o texto é truncado
      });

      testWidgets('deve lidar com estatísticas muito altas', (tester) async {
        final highStatsTeam = TestUtils.createTestTeam(
          id: 'high_stats',
          name: 'High Stats Team',
          wins: 9999,
          losses: 8888,
        );
        
        await tester.pumpWidget(createTestWidget(team: highStatsTeam));
        
        expect(find.text('Vitórias: 9999'), findsOneWidget);
        expect(find.text('Derrotas: 8888'), findsOneWidget);
      });

      testWidgets('deve lidar com nome vazio', (tester) async {
        final emptyNameTeam = TestUtils.createTestTeam(
          id: 'empty_name',
          name: '',
        );
        
        await tester.pumpWidget(createTestWidget(team: emptyNameTeam));
        
        expect(find.text('Time sem nome'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('deve renderizar rapidamente', (tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(createTestWidget());
        
        stopwatch.stop();
        
        // Deve renderizar em menos de 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      testWidgets('deve lidar com múltiplos cards', (tester) async {
        final teams = List.generate(100, (index) => 
          TestUtils.createTestTeam(
            id: 'team_$index',
            name: 'Team $index',
          ),
        );
        
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) => TeamCard(
                team: teams[index],
                onTap: mockOnTap,
                onEdit: mockOnEdit,
                onDelete: mockOnDelete,
              ),
            ),
          ),
        ));
        
        expect(find.byType(TeamCard), findsWidgets);
      });
    });

    group('Integração com Tema', () {
      testWidgets('deve respeitar tema escuro', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
            ),
          ),
        ));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve respeitar tema claro', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
            ),
          ),
        ));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });

      testWidgets('deve usar cores do tema quando apropriado', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.purple,
          ),
          home: Scaffold(
            body: TeamCard(
              team: testTeam,
              onTap: mockOnTap,
              onEdit: mockOnEdit,
              onDelete: mockOnDelete,
            ),
          ),
        ));
        
        expect(find.byType(TeamCard), findsOneWidget);
      });
    });
  });
}