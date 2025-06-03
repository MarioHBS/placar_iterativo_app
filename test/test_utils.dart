import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';

/// Utility class for common test setup and teardown operations
class TestUtils {
  /// Initialize Hive for testing environment
  static Future<void> initializeHiveForTesting() async {
    Hive.init('test');
    await HiveService.init(isTest: true);
  }

  /// Clear all Hive boxes used in the application
  static Future<void> clearAllHiveBoxes() async {
    final boxNames = [
      'teams',
      'matches',
      'game_configs',
      'tournaments',
      'theme_settings',
    ];

    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }

  /// Close all Hive boxes and clean up
  static Future<void> closeHive() async {
    await Hive.close();
  }

  /// Create a test widget wrapper with MaterialApp
  static Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Create a test widget wrapper with full app structure
  static Widget createFullTestWidget(Widget child) {
    return MaterialApp(
      title: 'Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Wait for all animations and async operations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Simulate a tap and wait for the result
  static Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Simulate entering text and wait for the result
  static Future<void> enterTextAndWait(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Simulate a long press and wait for the result
  static Future<void> longPressAndWait(
      WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// Simulate a drag gesture and wait for the result
  static Future<void> dragAndWait(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Verify that a widget exists and is visible
  static void verifyWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify that a widget does not exist
  static void verifyWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify that multiple widgets exist
  static void verifyMultipleWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Verify that at least one widget exists
  static void verifyAtLeastOneWidgetExists(Finder finder) {
    expect(finder, findsAtLeastNWidgets(1));
  }

  /// Create a mock team for testing
  static Map<String, dynamic> createMockTeam({
    String? id,
    String? name,
    Color? color,
    List<String>? members,
    String? emoji,
    int? wins,
    int? losses,
  }) {
    return {
      'id': id ?? 'test-team-${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Test Team',
      'color': color ?? Colors.blue,
      'members': members ?? ['Player 1', 'Player 2'],
      'emoji': emoji ?? '⚽',
      'wins': wins ?? 0,
      'losses': losses ?? 0,
      'consecutiveWins': 0,
      'isWaiting': false,
    };
  }

  /// Create a mock match for testing
  static Map<String, dynamic> createMockMatch({
    String? id,
    String? teamAId,
    String? teamBId,
    int? teamAScore,
    int? teamBScore,
    DateTime? startTime,
    DateTime? endTime,
    bool? isComplete,
  }) {
    return {
      'id': id ?? 'test-match-${DateTime.now().millisecondsSinceEpoch}',
      'teamAId': teamAId ?? 'team-a',
      'teamBId': teamBId ?? 'team-b',
      'teamAScore': teamAScore ?? 0,
      'teamBScore': teamBScore ?? 0,
      'startTime': startTime ?? DateTime.now(),
      'endTime': endTime,
      'durationInSeconds': 0,
      'isComplete': isComplete ?? false,
      'winnerId': null,
      'loserId': null,
    };
  }

  /// Create a mock game config for testing
  static Map<String, dynamic> createMockGameConfig({
    String? id,
    String? gameMode,
    String? endCondition,
    int? timeLimit,
    int? scoreLimit,
  }) {
    return {
      'id': id ?? 'test-config-${DateTime.now().millisecondsSinceEpoch}',
      'gameMode': gameMode ?? 'free',
      'endCondition': endCondition,
      'timeLimit': timeLimit,
      'scoreLimit': scoreLimit,
      'winsForWaitingMode': 3,
      'totalMatches': null,
    };
  }

  /// Generate a unique ID for testing
  static String generateTestId([String? prefix]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix ?? 'test'}-$timestamp';
  }

  /// Create a list of mock teams for testing
  static List<Map<String, dynamic>> createMockTeamsList(int count) {
    return List.generate(count, (index) {
      return createMockTeam(
        id: 'team-$index',
        name: 'Team ${index + 1}',
        color: Colors.primaries[index % Colors.primaries.length],
      );
    });
  }

  /// Create a list of mock matches for testing
  static List<Map<String, dynamic>> createMockMatchesList(int count) {
    return List.generate(count, (index) {
      return createMockMatch(
        id: 'match-$index',
        teamAId: 'team-${index * 2}',
        teamBId: 'team-${index * 2 + 1}',
      );
    });
  }

  /// Simulate device orientation change
  static Future<void> changeOrientation(
    WidgetTester tester,
    Orientation orientation,
  ) async {
    final size = orientation == Orientation.portrait
        ? const Size(400, 800)
        : const Size(800, 400);

    await tester.binding.setSurfaceSize(size);
    await tester.pumpAndSettle();
  }

  /// Simulate app lifecycle state change
  static Future<void> changeAppLifecycleState(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('AppLifecycleState.resumed'),
      ),
      (data) {},
    );
    await tester.pumpAndSettle();
  }

  /// Simulate memory pressure
  static Future<void> simulateMemoryPressure(WidgetTester tester) async {
    // Simulate memory pressure by triggering a rebuild
    await tester.pumpAndSettle();
    // In a real scenario, this would trigger memory cleanup
    // For testing purposes, we just ensure the app handles it gracefully
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher to check if a color is approximately equal to another color
  static Matcher approximatelyEqualColor(Color expected, {int tolerance = 5}) {
    return predicate<Color>((actual) {
      return (actual.red - expected.red).abs() <= tolerance &&
          (actual.green - expected.green).abs() <= tolerance &&
          (actual.blue - expected.blue).abs() <= tolerance &&
          (actual.alpha - expected.alpha).abs() <= tolerance;
    }, 'approximately equal to $expected with tolerance $tolerance');
  }

  /// Matcher to check if a DateTime is approximately equal to another DateTime
  static Matcher approximatelyEqualDateTime(
    DateTime expected, {
    Duration tolerance = const Duration(seconds: 1),
  }) {
    return predicate<DateTime>((actual) {
      return actual.difference(expected).abs() <= tolerance;
    }, 'approximately equal to $expected with tolerance $tolerance');
  }

  /// Matcher to check if a list contains items in any order
  static Matcher containsInAnyOrder(List expected) {
    return predicate<List>((actual) {
      if (actual.length != expected.length) return false;
      for (final item in expected) {
        if (!actual.contains(item)) return false;
      }
      return true;
    }, 'contains items $expected in any order');
  }
}
