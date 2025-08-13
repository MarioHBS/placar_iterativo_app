/// Configurações globais para os testes
class TestConfig {
  // Timeouts para diferentes tipos de teste
  static const Duration unitTestTimeout = Duration(seconds: 30);
  static const Duration widgetTestTimeout = Duration(seconds: 60);
  static const Duration integrationTestTimeout = Duration(minutes: 5);
  static const Duration performanceTestTimeout = Duration(minutes: 10);
  
  // Configurações de performance
  static const int maxTeamsForPerformanceTest = 10000;
  static const int maxMatchesForPerformanceTest = 5000;
  static const int maxConcurrentOperations = 100;
  
  // Limites de tempo para operações
  static const int maxCreateTimeMs = 1000;
  static const int maxSearchTimeMs = 200;
  static const int maxRenderTimeMs = 100;
  
  // Configurações de dados de teste
  static const String testDatabasePath = 'test_database';
  static const String testBackupPath = 'test_backups';
  
  // Configurações de mock
  static const bool useMockServices = true;
  static const bool enableTestLogging = false;
  
  // Configurações de UI
  static const double testScreenWidth = 400.0;
  static const double testScreenHeight = 800.0;
  static const double largeScreenWidth = 1200.0;
  static const double largeScreenHeight = 800.0;
  
  // Configurações de acessibilidade
  static const bool testAccessibility = true;
  static const bool testSemantics = true;
  
  // Configurações de internacionalização
  static const String defaultLocale = 'pt_BR';
  static const List<String> supportedLocales = ['pt_BR', 'en_US'];
  
  // Configurações de tema
  static const bool testDarkTheme = true;
  static const bool testLightTheme = true;
  
  // Configurações de rede (para testes de integração)
  static const Duration networkTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  
  // Configurações de backup
  static const int maxBackupsToKeep = 5;
  static const Duration backupRetentionPeriod = Duration(days: 30);
  
  // Configurações de logging para testes
  static void log(String message) {
    if (enableTestLogging) {
      print('[TEST] $message');
    }
  }
  
  // Configurações específicas por ambiente
  static bool get isCI => 
      const bool.fromEnvironment('CI', defaultValue: false);
  
  static bool get isDebug => 
      const bool.fromEnvironment('DEBUG', defaultValue: true);
  
  static bool get runPerformanceTests => 
      const bool.fromEnvironment('PERFORMANCE_TESTS', defaultValue: false);
  
  static bool get runIntegrationTests => 
      const bool.fromEnvironment('INTEGRATION_TESTS', defaultValue: true);
}

/// Configurações específicas para diferentes tipos de teste
class UnitTestConfig {
  static const int sampleDataSize = 100;
  static const Duration operationTimeout = Duration(seconds: 5);
  static const bool validateAllFields = true;
}

class WidgetTestConfig {
  static const Duration pumpDuration = Duration(milliseconds: 100);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const bool testAnimations = true;
  static const bool testGestures = true;
}

class IntegrationTestConfig {
  static const Duration pageTransitionTimeout = Duration(seconds: 3);
  static const Duration dataLoadTimeout = Duration(seconds: 10);
  static const bool testRealData = false;
  static const bool testOfflineMode = true;
}

class PerformanceTestConfig {
  static const int warmupIterations = 5;
  static const int measurementIterations = 10;
  static const double acceptableVariance = 0.2; // 20%
  static const bool profileMemory = true;
  static const bool profileCPU = true;
}