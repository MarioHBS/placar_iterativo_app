import 'dart:io';
import 'dart:async';

/// Script para executar todos os tipos de teste de forma organizada
void main(List<String> args) async {
  final testRunner = TestRunner();
  
  print('🧪 Iniciando execução completa de testes...');
  print('=' * 60);
  
  try {
    await testRunner.runAllTests(args);
    print('\n✅ Todos os testes foram executados com sucesso!');
  } catch (e) {
    print('\n❌ Erro durante a execução dos testes: $e');
    exit(1);
  }
}

class TestRunner {
  final List<TestSuite> _testSuites = [];
  final Map<String, TestResult> _results = {};
  
  TestRunner() {
    _initializeTestSuites();
  }
  
  void _initializeTestSuites() {
    _testSuites.addAll([
      TestSuite(
        name: 'Unit Tests',
        description: 'Testes unitários para models, providers e services',
        command: 'flutter test test/models test/providers test/services',
        icon: '🔧',
        timeout: const Duration(minutes: 5),
      ),
      TestSuite(
        name: 'Widget Tests',
        description: 'Testes de widgets e componentes UI',
        command: 'flutter test test/widgets',
        icon: '🎨',
        timeout: const Duration(minutes: 3),
      ),
      TestSuite(
        name: 'Integration Tests',
        description: 'Testes de integração end-to-end',
        command: 'flutter test test/integration',
        icon: '🔗',
        timeout: const Duration(minutes: 10),
        skipInCI: false,
      ),
      TestSuite(
        name: 'Performance Tests',
        description: 'Testes de performance e stress',
        command: 'flutter test test/performance',
        icon: '⚡',
        timeout: const Duration(minutes: 15),
        skipInCI: true, // Pular no CI por serem demorados
      ),
    ]);
  }
  
  Future<void> runAllTests(List<String> args) async {
    final options = _parseArguments(args);
    
    print('Configurações:');
    print('  - Modo verboso: ${options.verbose}');
    print('  - Cobertura: ${options.coverage}');
    print('  - Apenas falhas: ${options.failuresOnly}');
    print('  - Ambiente CI: ${options.isCI}');
    print('');
    
    final suitesToRun = _filterTestSuites(options);
    
    for (final suite in suitesToRun) {
      await _runTestSuite(suite, options);
    }
    
    _printSummary();
    
    if (options.coverage) {
      await _generateCoverageReport();
    }
  }
  
  TestOptions _parseArguments(List<String> args) {
    return TestOptions(
      verbose: args.contains('--verbose') || args.contains('-v'),
      coverage: args.contains('--coverage') || args.contains('-c'),
      failuresOnly: args.contains('--failures-only') || args.contains('-f'),
      isCI: Platform.environment['CI'] == 'true',
      skipPerformance: args.contains('--skip-performance'),
      skipIntegration: args.contains('--skip-integration'),
      pattern: _extractPattern(args),
    );
  }
  
  String? _extractPattern(List<String> args) {
    final patternIndex = args.indexOf('--pattern');
    if (patternIndex != -1 && patternIndex + 1 < args.length) {
      return args[patternIndex + 1];
    }
    return null;
  }
  
  List<TestSuite> _filterTestSuites(TestOptions options) {
    return _testSuites.where((suite) {
      if (options.skipPerformance && suite.name.contains('Performance')) {
        return false;
      }
      if (options.skipIntegration && suite.name.contains('Integration')) {
        return false;
      }
      if (options.isCI && suite.skipInCI) {
        return false;
      }
      return true;
    }).toList();
  }
  
  Future<void> _runTestSuite(TestSuite suite, TestOptions options) async {
    print('${suite.icon} Executando: ${suite.name}');
    print('   ${suite.description}');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await _executeCommand(
        suite.command,
        timeout: suite.timeout,
        verbose: options.verbose,
      );
      
      stopwatch.stop();
      
      _results[suite.name] = TestResult(
        suite: suite,
        success: result.exitCode == 0,
        duration: stopwatch.elapsed,
        output: result.output,
        error: result.error,
      );
      
      if (result.exitCode == 0) {
        print('   ✅ Sucesso (${_formatDuration(stopwatch.elapsed)})');
      } else {
        print('   ❌ Falha (${_formatDuration(stopwatch.elapsed)})');
        if (!options.verbose) {
          print('   Erro: ${result.error}');
        }
      }
    } catch (e) {
      stopwatch.stop();
      
      _results[suite.name] = TestResult(
        suite: suite,
        success: false,
        duration: stopwatch.elapsed,
        output: '',
        error: e.toString(),
      );
      
      print('   ❌ Erro: $e');
    }
    
    print('');
  }
  
  Future<CommandResult> _executeCommand(
    String command,
    {
    Duration? timeout,
    bool verbose = false,
  }) async {
    final parts = command.split(' ');
    final executable = parts.first;
    final arguments = parts.skip(1).toList();
    
    if (verbose) {
      print('   Executando: $command');
    }
    
    final process = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.normal,
    );
    
    final outputBuffer = StringBuffer();
    final errorBuffer = StringBuffer();
    
    // Capturar saída
    process.stdout.transform(const SystemEncoding().decoder).listen((data) {
      outputBuffer.write(data);
      if (verbose) {
        stdout.write(data);
      }
    });
    
    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      errorBuffer.write(data);
      if (verbose) {
        stderr.write(data);
      }
    });
    
    // Aguardar conclusão com timeout
    int exitCode;
    if (timeout != null) {
      final result = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();
          throw TimeoutException('Comando excedeu timeout de ${_formatDuration(timeout)}');
        },
      );
      exitCode = result;
    } else {
      exitCode = await process.exitCode;
    }
    
    return CommandResult(
      exitCode: exitCode,
      output: outputBuffer.toString(),
      error: errorBuffer.toString(),
    );
  }
  
  void _printSummary() {
    print('📊 Resumo dos Testes');
    print('=' * 60);
    
    final successful = _results.values.where((r) => r.success).length;
    final failed = _results.values.where((r) => !r.success).length;
    final total = _results.length;
    
    print('Total de suítes: $total');
    print('Sucessos: $successful');
    print('Falhas: $failed');
    print('');
    
    // Detalhes por suíte
    for (final result in _results.values) {
      final status = result.success ? '✅' : '❌';
      final duration = _formatDuration(result.duration);
      print('$status ${result.suite.name} ($duration)');
    }
    
    print('');
    
    // Tempo total
    final totalDuration = _results.values
        .map((r) => r.duration)
        .fold(Duration.zero, (a, b) => a + b);
    print('Tempo total: ${_formatDuration(totalDuration)}');
    
    // Estatísticas
    if (_results.isNotEmpty) {
      final avgDuration = Duration(
        microseconds: totalDuration.inMicroseconds ~/ _results.length,
      );
      print('Tempo médio por suíte: ${_formatDuration(avgDuration)}');
    }
  }
  
  Future<void> _generateCoverageReport() async {
    print('\n📈 Gerando relatório de cobertura...');
    
    try {
      // Executar testes com cobertura
      await _executeCommand(
        'flutter test --coverage',
        timeout: const Duration(minutes: 10),
      );
      
      // Gerar relatório HTML
      await _executeCommand(
        'genhtml coverage/lcov.info -o coverage/html',
        timeout: const Duration(minutes: 2),
      );
      
      print('✅ Relatório de cobertura gerado em coverage/html/index.html');
    } catch (e) {
      print('❌ Erro ao gerar relatório de cobertura: $e');
    }
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class TestSuite {
  final String name;
  final String description;
  final String command;
  final String icon;
  final Duration timeout;
  final bool skipInCI;
  
  const TestSuite({
    required this.name,
    required this.description,
    required this.command,
    required this.icon,
    this.timeout = const Duration(minutes: 5),
    this.skipInCI = false,
  });
}

class TestOptions {
  final bool verbose;
  final bool coverage;
  final bool failuresOnly;
  final bool isCI;
  final bool skipPerformance;
  final bool skipIntegration;
  final String? pattern;
  
  const TestOptions({
    this.verbose = false,
    this.coverage = false,
    this.failuresOnly = false,
    this.isCI = false,
    this.skipPerformance = false,
    this.skipIntegration = false,
    this.pattern,
  });
}

class TestResult {
  final TestSuite suite;
  final bool success;
  final Duration duration;
  final String output;
  final String error;
  
  const TestResult({
    required this.suite,
    required this.success,
    required this.duration,
    required this.output,
    required this.error,
  });
}

class CommandResult {
  final int exitCode;
  final String output;
  final String error;
  
  const CommandResult({
    required this.exitCode,
    required this.output,
    required this.error,
  });
}

class TimeoutException implements Exception {
  final String message;
  
  const TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}