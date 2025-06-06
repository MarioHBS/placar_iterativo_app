import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/game_config_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/screens/scoreboard_screen.dart';
import 'package:placar_iterativo_app/screens/tournament_setup_screen.dart';

class GameConfigScreen extends StatefulWidget {
  const GameConfigScreen({super.key});

  @override
  State<GameConfigScreen> createState() => _GameConfigScreenState();
}

class _GameConfigScreenState extends State<GameConfigScreen> {
  GameMode _selectedMode = GameMode.tournament;
  EndCondition _selectedEndCondition = EndCondition.none;
  final _timeController = TextEditingController(text: '5');
  final _scoreController = TextEditingController(text: '10');
  final _streakController = TextEditingController(text: '3');
  final _maxMatchesController = TextEditingController();
  bool _waitingModeEnabled = true;

  Team? _teamA;
  Team? _teamB;

  late TeamsNotifier teamsNotifier;
  late GameConfigNotifier gameConfigNotifier;
  late MatchesNotifier matchesNotifier;

  @override
  void initState() {
    super.initState();
    teamsNotifier = Modular.get<TeamsNotifier>();
    gameConfigNotifier = Modular.get<GameConfigNotifier>();
    matchesNotifier = Modular.get<MatchesNotifier>();

    teamsNotifier.addListener(_onTeamsChanged);
    gameConfigNotifier.addListener(_onGameConfigChanged);
    matchesNotifier.addListener(_onMatchesChanged);
  }

  void _onTeamsChanged() {
    setState(() {});
  }

  void _onGameConfigChanged() {
    setState(() {});
  }

  void _onMatchesChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    teamsNotifier.removeListener(_onTeamsChanged);
    gameConfigNotifier.removeListener(_onGameConfigChanged);
    matchesNotifier.removeListener(_onMatchesChanged);

    _timeController.dispose();
    _scoreController.dispose();
    _streakController.dispose();
    _maxMatchesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nova Partida',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (teamsNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teamsNotifier.error != null) {
      return Center(
        child: Text('Erro: ${teamsNotifier.error}'),
      );
    }

    final teams = teamsNotifier.teams;
    final teamsList = teams.values.toList();

    if (teamsList.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'É necessário ter pelo menos 2 times cadastrados',
              style: GoogleFonts.roboto(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/teams');
              },
              child: const Text('Cadastrar Times'),
            ),
          ],
        ),
      );
    }

    return _buildGameConfigForm(teamsList);
  }

  Widget _buildGameConfigForm(List<Team> teamsList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeSelection(),
          const SizedBox(height: 32),
          _buildTeamSelection(teamsList),
          const SizedBox(height: 32),
          if (_selectedMode == GameMode.tournament) ...[
            _buildTournamentSettings(),
            const SizedBox(height: 32),
          ],
          _buildEndConditionSettings(),
          const SizedBox(height: 40),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modo de Jogo',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              title: 'Torneio',
              icon: Icons.emoji_events,
              description: 'Gerenciamento de fila e regras de término',
              isSelected: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelection(List<Team> teams) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedMode == GameMode.tournament
                  ? 'Times Iniciais'
                  : 'Selecionar Times',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTeamDropdown(
                    label: 'Time A',
                    teams: teams,
                    selectedTeam: _teamA,
                    onChanged: (team) => setState(() => _teamA = team),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamDropdown(
                    label: 'Time B',
                    teams: teams,
                    selectedTeam: _teamB,
                    onChanged: (team) => setState(() => _teamB = team),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDropdown({
    required String label,
    required List<Team> teams,
    required Team? selectedTeam,
    required Function(Team?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Team>(
              isExpanded: true,
              value: selectedTeam,
              hint: const Text('Selecione'),
              items: teams.map((team) {
                return DropdownMenuItem<Team>(
                  value: team,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: team.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: team.color, width: 1),
                        ),
                        child: Center(
                          child: team.imagePath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(team.imagePath!),
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        team.emoji ?? '🏆',
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  team.emoji ?? '🏆',
                                  style: const TextStyle(fontSize: 12),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => onChanged(value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações do Torneio',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Waiting Mode Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Modo Espera',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _waitingModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _waitingModeEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    label: 'Vitórias para Modo Espera',
                    controller: _streakController,
                    hint: '3',
                    enabled: _waitingModeEnabled,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    label: 'Número Total de Partidas (opcional)',
                    controller: _maxMatchesController,
                    hint: 'Ilimitado',
                    isRequired: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndConditionSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condições de Término',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEndConditionRadio(
              title: 'Sem limite',
              value: EndCondition.none,
              groupValue: _selectedEndCondition,
              onChanged: (value) =>
                  setState(() => _selectedEndCondition = value!),
            ),
            _buildEndConditionRadio(
              title: 'Por tempo',
              value: EndCondition.time,
              groupValue: _selectedEndCondition,
              onChanged: (value) =>
                  setState(() => _selectedEndCondition = value!),
            ),
            if (_selectedEndCondition == EndCondition.time)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                child: _buildNumberField(
                  label: 'Tempo limite (minutos)',
                  controller: _timeController,
                  hint: '5',
                ),
              ),
            _buildEndConditionRadio(
              title: 'Por pontuação',
              value: EndCondition.score,
              groupValue: _selectedEndCondition,
              onChanged: (value) =>
                  setState(() => _selectedEndCondition = value!),
            ),
            if (_selectedEndCondition == EndCondition.score)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                child: _buildNumberField(
                  label: 'Pontuação limite',
                  controller: _scoreController,
                  hint: '10',
                ),
              ),
            _buildEndConditionRadio(
              title: 'Por tempo ou pontuação',
              value: EndCondition.both,
              groupValue: _selectedEndCondition,
              onChanged: (value) =>
                  setState(() => _selectedEndCondition = value!),
            ),
            if (_selectedEndCondition == EndCondition.both)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 8),
                child: Column(
                  children: [
                    _buildNumberField(
                      label: 'Tempo limite (minutos)',
                      controller: _timeController,
                      hint: '5',
                    ),
                    const SizedBox(height: 8),
                    _buildNumberField(
                      label: 'Pontuação limite',
                      controller: _scoreController,
                      hint: '10',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndConditionRadio({
    required String title,
    required EndCondition value,
    required EndCondition groupValue,
    required Function(EndCondition?) onChanged,
  }) {
    return RadioListTile<EndCondition>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = true,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _validateAndStart,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        'Iniciar Partida',
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _validateAndStart() async {
    // Validate team selection
    if (_teamA == null || _teamB == null) {
      _showErrorSnackBar('Selecione dois times diferentes');
      return;
    }

    if (_teamA!.id == _teamB!.id) {
      _showErrorSnackBar('Selecione times diferentes');
      return;
    }

    // Check if providers are initialized
    if (gameConfigNotifier.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde a inicialização...'),
        ),
      );
      return;
    }

    if (gameConfigNotifier.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na inicialização: ${gameConfigNotifier.error}'),
        ),
      );
      return;
    }

    if (matchesNotifier.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde a inicialização das partidas...'),
        ),
      );
      return;
    }

    if (matchesNotifier.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro na inicialização das partidas: ${matchesNotifier.error}'),
        ),
      );
      return;
    }

    // Validate end condition settings
    int? timeLimit;
    int? scoreLimit;
    int? winsForWaitingMode;
    int? totalMatches;

    if (_selectedMode == GameMode.tournament) {
      switch (_selectedEndCondition) {
        case EndCondition.time:
          timeLimit = int.tryParse(_timeController.text);
          if (timeLimit == null || timeLimit <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Tempo limite deve ser um número válido maior que 0'),
              ),
            );
            return;
          }
          break;
        case EndCondition.score:
          scoreLimit = int.tryParse(_scoreController.text);
          if (scoreLimit == null || scoreLimit <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Pontuação limite deve ser um número válido maior que 0'),
              ),
            );
            return;
          }
          break;
        case EndCondition.both:
          timeLimit = int.tryParse(_timeController.text);
          scoreLimit = int.tryParse(_scoreController.text);
          if (timeLimit == null || timeLimit <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Tempo limite deve ser um número válido maior que 0'),
              ),
            );
            return;
          }
          if (scoreLimit == null || scoreLimit <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Pontuação limite deve ser um número válido maior que 0'),
              ),
            );
            return;
          }
          break;
        case EndCondition.none:
          break;
      }

      if (_waitingModeEnabled) {
        winsForWaitingMode = int.tryParse(_streakController.text);
        if (winsForWaitingMode == null || winsForWaitingMode <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sequência de vitórias deve ser um número válido maior que 0'),
            ),
          );
          return;
        }
      } else {
        winsForWaitingMode = 3; // Default value when waiting mode is disabled
      }

      if (_maxMatchesController.text.isNotEmpty) {
        totalMatches = int.tryParse(_maxMatchesController.text);
        if (totalMatches == null || totalMatches <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Número de partidas deve ser um número válido maior que 0'),
            ),
          );
          return;
        }
      }
    }

    // Create tournament mode config
    gameConfigNotifier
        .createTournamentMode(
      endCondition: _selectedEndCondition,
      timeLimit: timeLimit,
      scoreLimit: scoreLimit,
      winsForWaitingMode: winsForWaitingMode ?? 3,
      totalMatches: totalMatches,
      waitingModeEnabled: _waitingModeEnabled,
    )
        .then((config) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentSetupScreen(
              initialTeamA: _teamA!,
              initialTeamB: _teamB!,
              gameConfig: config,
            ),
          ),
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
