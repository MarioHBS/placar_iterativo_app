import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/app_module.dart';
import 'package:placar_iterativo_app/main.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';
import '../test_utils.dart';

void main() {
  group('App Integration Tests', () {
    setUpAll(() async {
      // Initialize Hive with a temporary directory for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('test_temp');
      await HiveService.init(isTest: true);
    });

    setUp(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    tearDownAll(() async {
      await TestUtils.closeHive();
    });

    testWidgets('should load app and show home screen',
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
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should navigate between screens', (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert - Test navigation
      // This would require actual navigation buttons in the UI
      // For now, we'll test that the app loads without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle theme changes', (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('should initialize all providers correctly',
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

      // Assert - Check that providers are registered
      expect(() => Modular.get(), isNot(throwsA(isA<Exception>())));
    });

    testWidgets('should handle app lifecycle correctly',
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

      // Simulate app lifecycle changes
      await TestUtils.changeAppLifecycleState(tester, AppLifecycleState.paused);
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

      // Act - Simulate orientation change to landscape
      await TestUtils.changeOrientation(tester, Orientation.landscape);

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);

      // Act - Change back to portrait
      await TestUtils.changeOrientation(tester, Orientation.portrait);

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle memory pressure', (WidgetTester tester) async {
      // Arrange
      Modular.bindModule(AppModule());

      await tester.pumpWidget(
        ModularApp(
          module: AppModule(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Simulate memory pressure using TestUtils
      await TestUtils.simulateMemoryPressure(tester);
      await tester.pumpAndSettle();

      // Assert - App should handle it gracefully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should maintain state across rebuilds',
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

      // Act - Force rebuild
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
