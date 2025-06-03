# 🧪 Testes do Placar Iterativo App

Este diretório contém todos os testes automatizados para o aplicativo Placar Iterativo. Os testes são organizados por categoria e cobrem diferentes aspectos da aplicação.

## 📁 Estrutura dos Testes

```
test/
├── models/                     # Testes dos modelos de dados
│   ├── team_test.dart         # Testes do modelo Team
│   ├── match_test.dart        # Testes do modelo Match
│   └── game_config_test.dart  # Testes do modelo GameConfig
├── providers/                  # Testes dos providers (gerenciamento de estado)
│   ├── teams_provider_test.dart
│   └── current_game_provider_test.dart
├── services/                   # Testes dos serviços
│   └── hive_service_test.dart # Testes do serviço de persistência
├── widgets/                    # Testes dos widgets customizados
│   └── animated_widgets_test.dart
├── integration/                # Testes de integração
│   └── app_integration_test.dart
├── test_utils.dart            # Utilitários para testes
├── all_tests.dart             # Executa todos os testes
└── README.md                  # Este arquivo
```

## 🚀 Como Executar os Testes

### Executar Todos os Testes
```bash
# Executa todos os testes da aplicação
flutter test

# Ou executar o arquivo principal de testes
flutter test test/all_tests.dart
```

### Executar Testes Específicos

#### Testes de Modelos
```bash
# Todos os testes de modelos
flutter test test/models/

# Teste específico do modelo Team
flutter test test/models/team_test.dart

# Teste específico do modelo Match
flutter test test/models/match_test.dart

# Teste específico do modelo GameConfig
flutter test test/models/game_config_test.dart
```

#### Testes de Providers
```bash
# Todos os testes de providers
flutter test test/providers/

# Teste específico do TeamsProvider
flutter test test/providers/teams_provider_test.dart

# Teste específico do CurrentGameProvider
flutter test test/providers/current_game_provider_test.dart
```

#### Testes de Serviços
```bash
# Todos os testes de serviços
flutter test test/services/

# Teste específico do HiveService
flutter test test/services/hive_service_test.dart
```

#### Testes de Widgets
```bash
# Todos os testes de widgets
flutter test test/widgets/

# Teste específico dos widgets animados
flutter test test/widgets/animated_widgets_test.dart
```

#### Testes de Integração
```bash
# Todos os testes de integração
flutter test test/integration/

# Teste específico de integração da app
flutter test test/integration/app_integration_test.dart
```

### Executar com Cobertura de Código
```bash
# Instalar a ferramenta de cobertura (se não estiver instalada)
flutter pub global activate coverage

# Executar testes com cobertura
flutter test --coverage

# Gerar relatório HTML de cobertura
genhtml coverage/lcov.info -o coverage/html

# Abrir relatório no navegador (Windows)
start coverage/html/index.html
```

### Executar em Modo Watch (Desenvolvimento)

O Flutter não possui um comando `--watch` nativo. Use uma das alternativas abaixo:

#### Opção 1: Script PowerShell (Windows - Recomendado)
```powershell
# Execute o script incluído no projeto
.\test\watch_tests.ps1
```

#### Opção 2: Usar nodemon (Cross-platform)
```bash
# Instalar nodemon globalmente
npm install -g nodemon

# Executar com nodemon
nodemon --exec "flutter test" --ext dart --watch lib/ --watch test/
```

#### Opção 3: VS Code com extensão Flutter
- Instale a extensão Flutter no VS Code
- Use `Ctrl+Shift+P` > "Flutter: Run Tests"
- Os testes serão executados automaticamente quando arquivos forem salvos

#### Opção 4: Usar entr (Linux/macOS)
```bash
# Instalar entr primeiro
# No macOS: brew install entr
# No Linux: apt-get install entr

# Executar
find lib test -name "*.dart" | entr -r flutter test
```

## 📊 Tipos de Testes

### 1. **Testes Unitários** 🔬
- **Modelos**: Testam a lógica de negócio dos modelos de dados
- **Providers**: Testam o gerenciamento de estado e lógica de negócio
- **Serviços**: Testam a persistência de dados e serviços externos

### 2. **Testes de Widget** 🎨
- Testam componentes de UI individuais
- Verificam renderização e interações
- Testam animações e transições

### 3. **Testes de Integração** 🔗
- Testam fluxos completos da aplicação
- Verificam integração entre componentes
- Testam navegação e estado global

## 🛠️ Utilitários de Teste

O arquivo `test_utils.dart` contém funções auxiliares para:

- **Configuração do Hive**: Inicialização e limpeza do banco de dados
- **Widgets de Teste**: Wrappers para facilitar testes de UI
- **Simulações**: Gestos, orientação, ciclo de vida da app
- **Mocks**: Criação de dados de teste
- **Matchers Customizados**: Verificações específicas da aplicação

### Exemplo de Uso dos Utilitários
```dart
import '../test_utils.dart';

void main() {
  group('Meu Teste', () {
    setUp(() async {
      await TestUtils.initializeHiveForTesting();
    });

    tearDown(() async {
      await TestUtils.clearAllHiveBoxes();
    });

    testWidgets('deve renderizar widget', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestWidget(MeuWidget()),
      );
      
      TestUtils.verifyWidgetExists(find.text('Texto Esperado'));
    });
  });
}
```

## 📈 Cobertura de Testes

Os testes cobrem:

- ✅ **Modelos de Dados**: Team, Match, GameConfig, Tournament
- ✅ **Providers**: TeamsProvider, CurrentGameProvider
- ✅ **Serviços**: HiveService (persistência)
- ✅ **Widgets**: Componentes animados
- ✅ **Integração**: Fluxos principais da aplicação

## 🐛 Debugging de Testes

### Executar Testes em Modo Debug
```bash
# Executar com informações detalhadas
flutter test --verbose

# Executar teste específico com debug
flutter test test/models/team_test.dart --verbose
```

### Logs e Debugging
```dart
// Adicionar logs nos testes
test('meu teste', () {
  debugPrint('Iniciando teste...');
  // código do teste
  debugPrint('Teste finalizado.');
});
```

## 📝 Convenções de Teste

### Nomenclatura
- Arquivos de teste terminam com `_test.dart`
- Grupos de teste usam `group('Nome do Grupo', () {})`
- Testes individuais usam `test('deve fazer algo', () {})`
- Testes de widget usam `testWidgets('deve renderizar', (tester) async {})`

### Estrutura AAA (Arrange, Act, Assert)
```dart
test('deve calcular corretamente', () {
  // Arrange - Preparar dados
  final team = Team(id: '1', name: 'Test', color: Colors.blue);
  
  // Act - Executar ação
  final result = team.calculateWinRate();
  
  // Assert - Verificar resultado
  expect(result, equals(0.0));
});
```

### Limpeza de Recursos
```dart
group('Meus Testes', () {
  setUp(() {
    // Configuração antes de cada teste
  });
  
  tearDown(() {
    // Limpeza após cada teste
  });
  
  setUpAll(() {
    // Configuração uma vez antes de todos os testes
  });
  
  tearDownAll(() {
    // Limpeza uma vez após todos os testes
  });
});
```

## 🔧 Configuração de CI/CD

Para integração contínua, adicione ao seu workflow:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
```

## 📚 Recursos Adicionais

- [Documentação Oficial de Testes Flutter](https://docs.flutter.dev/testing)
- [Cookbook de Testes](https://docs.flutter.dev/cookbook/testing)
- [Melhores Práticas de Teste](https://docs.flutter.dev/testing/best-practices)

---

**Nota**: Certifique-se de que todos os testes passem antes de fazer commit das suas alterações. Use `flutter test` para verificar.