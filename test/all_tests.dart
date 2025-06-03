import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'models/team_test.dart' as team_tests;
import 'models/match_test.dart' as match_tests;
import 'models/game_config_test.dart' as game_config_tests;
import 'providers/teams_provider_test.dart' as teams_provider_tests;
import 'providers/current_game_provider_test.dart'
    as current_game_provider_tests;
import 'services/hive_service_test.dart' as hive_service_tests;
import 'widgets/animated_widgets_test.dart' as animated_widgets_tests;
import 'integration/app_integration_test.dart' as app_integration_tests;

/// Main test suite that runs all tests in the application
///
/// This file imports and runs all test suites to provide a comprehensive
/// test coverage of the entire application.
///
/// To run all tests, use: flutter test test/all_tests.dart
void main() {
  group('🏆 Placar Iterativo App - Complete Test Suite', () {
    group('📊 Model Tests', () {
      group('Team Model', team_tests.main);
      group('Match Model', match_tests.main);
      group('GameConfig Model', game_config_tests.main);
    });

    group('🔄 Provider Tests', () {
      group('Teams Provider', teams_provider_tests.main);
      group('Current Game Provider', current_game_provider_tests.main);
    });

    group('🛠️ Service Tests', () {
      group('Hive Service', hive_service_tests.main);
    });

    group('🎨 Widget Tests', () {
      group('Animated Widgets', animated_widgets_tests.main);
    });

    group('🔗 Integration Tests', () {
      group('App Integration', app_integration_tests.main);
    });
  });
}
