# 🧪 Estrutura de Testes - Placar Interativo

Este documento descreve a estrutura completa de testes do projeto Placar Interativo, incluindo organização, padrões de nomenclatura e instruções de execução.

## 📁 Estrutura de Pastas

```
test/
├── models/                    # Testes unitários para models
│   ├── team_test.dart
│   ├── match_test.dart
│   ├── tournament_test.dart
│   └── game_config_test.dart
├── providers/                 # Testes unitários para providers
│   ├── teams_provider_test.dart
│   ├── matches_provider_test.dart
│   ├── tournament_provider_test.dart
│   └── game_provider_test.dart
├── services/                  # Testes unitários para services
│   ├── hive_service_test.dart
│   ├── audio_service_test.dart
│   ├── tts_service_test.dart
│   └── backup_service_test.dart
├── widgets/                   # Testes de widgets
│   ├── score_board_test.dart
│   └── team_card_test.dart
├── integration/               # Testes de integração
│   └── app_integration_test.dart
├── performance/               # Testes de performance
│   └── performance_test.dart
├── utils/                     # Utilitários para testes
│   └── test_utils.dart
├── test_config.dart          # Configurações globais de teste
├── run_all_tests.dart        # Script para executar todos os testes
└── README.md                 # Este arquivo
```

## 🏷️ Padrões de Nomenclatura

### Arquivos de Teste
- **Formato**: `{nome_da_classe}_test.dart`
- **Exemplos**: 
  - `team_test.dart` para a classe `Team`
  - `teams_provider_test.dart` para a classe `TeamsProvider`
  - `score_board_test.dart` para o widget `ScoreBoard`

### Grupos de Teste
- **Formato**: Nome da classe ou funcionalidade sendo testada
- **Exemplos**:
  ```dart
  group('Team', () { ... });
  group('TeamsProvider', () { ... });
  group('ScoreBoard Widget', () { ... });
  ```

### Casos de Teste
- **Formato**: Descrição clara do comportamento esperado
- **Padrões**:
  - `should {ação} when {condição}`
  - `should return {resultado} when {entrada}`
  - `should throw {exceção} when {condição inválida}`

**Exemplos**:
```dart
test('should create team with valid data', () { ... });
test('should return empty list when no teams exist', () { ... });
test('should throw exception when name is empty', () { ... });
```

## 🎯 Tipos de Teste

### 1. Testes Unitários
**Localização**: `test/models/`, `test/providers/`, `test/services/`

**Objetivo**: Testar unidades isoladas de código

**Características**:
- Rápidos de executar
- Testam uma única funcionalidade
- Usam mocks para dependências
- Alta cobertura de código

### 2. Testes de Widget
**Localização**: `test/widgets/`

**Objetivo**: Testar componentes de UI

**Características**:
- Testam renderização e interações
- Verificam acessibilidade
- Testam responsividade
- Usam `WidgetTester`

### 3. Testes de Integração
**Localização**: `test/integration/`

**Objetivo**: Testar fluxos completos da aplicação

**Características**:
- Testam múltiplos componentes juntos
- Simulam interações do usuário
- Verificam fluxos end-to-end
- Mais lentos que testes unitários

### 4. Testes de Performance
**Localização**: `test/performance/`

**Objetivo**: Verificar performance e limites do sistema

**Características**:
- Testam com grandes volumes de dados
- Medem tempo de execução
- Verificam uso de memória
- Testam operações concorrentes

## 🚀 Como Executar os Testes

### Executar Todos os Testes
```bash
# Usando o script personalizado
dart test/run_all_tests.dart

# Com opções
dart test/run_all_tests.dart --verbose --coverage

# Comando Flutter padrão
flutter test
```

### Executar Tipos Específicos
```bash
# Apenas testes unitários
flutter test test/models test/providers test/services

# Apenas testes de widget
flutter test test/widgets

# Apenas testes de integração
flutter test test/integration

# Apenas testes de performance
flutter test test/performance
```

### Executar Arquivo Específico
```bash
# Teste específico
flutter test test/models/team_test.dart

# Com modo verboso
flutter test test/models/team_test.dart --verbose
```

### Opções do Script Personalizado
```bash
# Modo verboso (mostra saída detalhada)
dart test/run_all_tests.dart --verbose

# Gerar relatório de cobertura
dart test/run_all_tests.dart --coverage

# Pular testes de performance
dart test/run_all_tests.dart --skip-performance

# Pular testes de integração
dart test/run_all_tests.dart --skip-integration

# Apenas mostrar falhas
dart test/run_all_tests.dart --failures-only
```

## 📊 Cobertura de Código

### Gerar Relatório
```bash
# Executar testes com cobertura
flutter test --coverage

# Gerar relatório HTML (requer lcov)
genhtml coverage/lcov.info -o coverage/html

# Ou usar o script personalizado
dart test/run_all_tests.dart --coverage
```

### Visualizar Relatório
Abra o arquivo `coverage/html/index.html` no navegador.

## 🛠️ Configurações

### Arquivo de Configuração
O arquivo `test_config.dart` contém configurações globais:

```dart
class TestConfig {
  // Timeouts para diferentes tipos de teste
  static const Duration unitTestTimeout = Duration(seconds: 30);
  static const Duration widgetTestTimeout = Duration(minutes: 2);
  static const Duration integrationTestTimeout = Duration(minutes: 5);
  static const Duration performanceTestTimeout = Duration(minutes: 10);
  
  // Parâmetros de performance
  static const int performanceTestIterations = 1000;
  static const int largeDatasetSize = 10000;
  
  // E muito mais...
}
```

### Utilitários de Teste
O arquivo `test_utils.dart` fornece funções auxiliares:

```dart
class TestUtils {
  // Inicialização do Hive para testes
  static Future<void> initializeHive() async { ... }
  
  // Limpeza após testes
  static Future<void> cleanupHive() async { ... }
  
  // Criação de dados de teste
  static Team createTestTeam({String? name, Color? color}) { ... }
  
  // E muito mais...
}
```

## 📋 Checklist de Qualidade

Antes de fazer commit, verifique:

- [ ] Todos os testes passam
- [ ] Cobertura de código > 80%
- [ ] Testes seguem padrões de nomenclatura
- [ ] Casos edge estão cobertos
- [ ] Testes são independentes
- [ ] Mocks são usados adequadamente
- [ ] Performance está dentro dos limites

## 🔧 Ferramentas Recomendadas

### Extensões VS Code
- **Flutter Test Runner**: Execução visual de testes
- **Coverage Gutters**: Visualização de cobertura inline
- **Dart Code Metrics**: Análise de qualidade de código

### Comandos Úteis
```bash
# Executar testes em modo watch
flutter test --watch

# Executar com filtro de nome
flutter test --name "should create team"

# Executar com filtro de arquivo
flutter test --plain-name "team_test"

# Debug de teste específico
flutter test test/models/team_test.dart --debug
```

## 🐛 Solução de Problemas

### Problemas Comuns

1. **Testes falhando por dependências**
   - Verifique se todas as dependências estão mockadas
   - Use `TestUtils.initializeHive()` para testes que usam Hive

2. **Timeouts em testes de performance**
   - Ajuste os timeouts em `test_config.dart`
   - Use `--skip-performance` se necessário

3. **Problemas de cobertura**
   - Instale `lcov`: `sudo apt-get install lcov` (Linux)
   - No Windows, use WSL ou Docker

4. **Testes de widget falhando**
   - Verifique se `testWidgets` está sendo usado
   - Certifique-se de que `pumpAndSettle()` é chamado após interações

### Logs e Debug
```dart
// Habilitar logs em testes
setUpAll(() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
});
```

## 📚 Recursos Adicionais

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Performance Testing](https://docs.flutter.dev/testing/performance)

---

**Última atualização**: $(date)
**Versão**: 1.0.0
**Mantido por**: Equipe de Desenvolvimento