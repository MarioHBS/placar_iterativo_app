import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/app_module.dart';
import 'package:placar_iterativo_app/main.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import 'test_utils.dart';

void main() {
  group('Main App Widget Tests', () {
    setUpAll(() async {
      await TestUtils.initializeHiveForTesting();
    });

    setUp(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    tearDownAll(() async {
      await TestUtils.closeHive();
    });

    testWidgets('should create MyApp widget successfully',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MyApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should have correct app title', (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('Placar Interativo'));
    });

    testWidgets('should not show debug banner', (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('should have light and dark themes configured',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('should use Modular router configuration',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.routerConfig, isNotNull);
    });

    testWidgets('should handle theme changes through ThemeNotifier',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - App should be built with AnimatedBuilder for theme changes
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });

    testWidgets('should handle app lifecycle correctly',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Simulate app going to background
      await TestUtils.changeAppLifecycleState(tester, AppLifecycleState.paused);

      // Act - Simulate app coming back to foreground
      await TestUtils.changeAppLifecycleState(
          tester, AppLifecycleState.resumed);

      // Assert - App should still be functional
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle orientation changes',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Change to landscape
      await TestUtils.changeOrientation(tester, Orientation.landscape);

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);

      // Act - Change back to portrait
      await TestUtils.changeOrientation(tester, Orientation.portrait);

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should maintain state across rebuilds',
        (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      // Act - Build app
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Rebuild app
      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - App should still be functional
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
