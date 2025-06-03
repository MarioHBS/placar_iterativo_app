import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import 'package:placar_iterativo_app/screens/tournament_screen.dart';

class TournamentSetupScreen extends StatefulWidget {
  final Team initialTeamA;
  final Team initialTeamB;
  final GameConfig gameConfig;

  const TournamentSetupScreen({
    super.key,
    required this.initialTeamA,
    required this.initialTeamB,
    required this.gameConfig,
  });

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  late TeamsNotifier teamsNotifier;
  late TournamentNotifier tournamentNotifier;
  final _tournamentNameController = TextEditingController(text: 'Torneio');
  final List<Team> _selectedTeams = [];
  final List<Team> _availableTeams = [];

  @override
  void initState() {
    super.initState();
    teamsNotifier = Modular.get<TeamsNotifier>();
    tournamentNotifier = Modular.get<TournamentNotifier>();
    teamsNotifier.addListener(_onStateChanged);
    tournamentNotifier.addListener(_onStateChanged);
    // Add initial teams
    _selectedTeams.add(widget.initialTeamA);
    _selectedTeams.add(widget.initialTeamB);
  }

  @override
  void dispose() {
    _tournamentNameController.dispose();
    teamsNotifier.removeListener(_onStateChanged);
    tournamentNotifier.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  Widget _buildBody() {
    if (teamsNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teamsNotifier.error != null) {
      return Center(
        child: Text(
          'Error loading teams: ${teamsNotifier.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final teams = teamsNotifier.teams;
    // Update available teams
    _updateAvailableTeams(teams.values.toList());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTournamentNameField(),
          const SizedBox(height: 24),
          _buildTeamsSection(),
          const SizedBox(height: 32),
          _buildStartButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configurar Torneio',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  void _updateAvailableTeams(List<Team> allTeams) {
    // Clear the available teams list
    _availableTeams.clear();

    // Add all teams that are not already selected
    for (final team in allTeams) {
      if (!_selectedTeams.any((selectedTeam) => selectedTeam.id == team.id)) {
        _availableTeams.add(team);
      }
    }
  }

  Widget _buildTournamentNameField() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome do Torneio',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tournamentNameController,
              decoration: const InputDecoration(
                hintText: 'Ex: Torneio de Verão',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Times Participantes',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedTeams.length} selecionados',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSelectedTeamsList(),
            const SizedBox(height: 16),
            _buildAddTeamButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTeamsList() {
    if (_selectedTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nenhum time selecionado',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _selectedTeams.map((team) => _buildTeamTile(team)).toList(),
    );
  }

  Widget _buildTeamTile(Team team) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: team.color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: team.color, width: 2),
        ),
        child: Center(
          child: team.imagePath != null
              ? ClipOval(
                  child: Image.file(
                    File(team.imagePath!),
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        team.emoji ?? '🏆',
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                )
              : Text(
                  team.emoji ?? '🏆',
                  style: const TextStyle(fontSize: 16),
                ),
        ),
      ),
      title: Text(
        team.name,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: team.members.isNotEmpty
          ? Text(
              team.members.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
        onPressed: () {
          setState(() {
            _selectedTeams.remove(team);
          });
        },
      ),
    );
  }

  Widget _buildAddTeamButton() {
    return ElevatedButton.icon(
      onPressed: _availableTeams.isEmpty ? null : _showAddTeamDialog,
      icon: const Icon(Icons.add),
      label: const Text('Adicionar Time'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  void _showAddTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Time'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableTeams.length,
            itemBuilder: (context, index) {
              final team = _availableTeams[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: team.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: team.color, width: 2),
                  ),
                  child: Center(
                    child: team.imagePath != null
                        ? ClipOval(
                            child: Image.file(
                              File(team.imagePath!),
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  team.emoji ?? '🏆',
                                  style: const TextStyle(fontSize: 16),
                                );
                              },
                            ),
                          )
                        : Text(
                            team.emoji ?? '🏆',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                title: Text(team.name),
                onTap: () {
                  setState(() {
                    _selectedTeams.add(team);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _selectedTeams.length >= 2 ? _startTournament : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: Text(
        'Iniciar Torneio',
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color:
              _selectedTeams.length >= 2 ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  void _startTournament() async {
    final tournamentName = _tournamentNameController.text.trim();
    if (tournamentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o torneio')),
      );
      return;
    }

    if (_selectedTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos 2 times')),
      );
      return;
    }

    // Create tournament
    final tournament = await tournamentNotifier.createTournament(
      name: tournamentName,
      config: widget.gameConfig,
      teams: _selectedTeams,
    );

    if (!mounted) return;

    // Navigate to tournament screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentScreen(tournament: tournament),
      ),
    );
  }
}
