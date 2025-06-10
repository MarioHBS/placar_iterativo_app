import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import 'package:placar_iterativo_app/screens/match_summary_screen.dart';
import 'package:placar_iterativo_app/screens/scoreboard_screen.dart';

class TournamentScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentScreen({super.key, required this.tournament});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  late TeamsNotifier teamsNotifier;
  late TournamentNotifier tournamentNotifier;
  late MatchesNotifier matchesNotifier;
  late Tournament _tournament;
  Match? _currentMatch;
  Team? _teamA;
  Team? _teamB;
  bool _isMatchInProgress = false;

  @override
  void initState() {
    super.initState();
    teamsNotifier = Modular.get<TeamsNotifier>();
    tournamentNotifier = Modular.get<TournamentNotifier>();
    matchesNotifier = Modular.get<MatchesNotifier>();
    teamsNotifier.addListener(_onStateChanged);
    tournamentNotifier.addListener(_onStateChanged);
    matchesNotifier.addListener(_onStateChanged);
    _tournament = widget.tournament;
    _loadNextMatch();
  }

  @override
  void dispose() {
    teamsNotifier.removeListener(_onStateChanged);
    tournamentNotifier.removeListener(_onStateChanged);
    matchesNotifier.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _loadNextMatch() {
    // Get the latest tournament data
    final latestTournament = tournamentNotifier.getTournament(_tournament.id);
    if (latestTournament != null) {
      _tournament = latestTournament;
    }

    // Check if tournament is complete
    if (_tournament.isComplete) {
      setState(() {
        _currentMatch = null;
        _teamA = null;
        _teamB = null;
        _isMatchInProgress = false;
      });
      return;
    }

    // Get the next match team IDs
    final teamIds = _tournament.getNextMatchTeamIds();
    if (teamIds == null || teamIds.length != 2) {
      setState(() {
        _currentMatch = null;
        _teamA = null;
        _teamB = null;
        _isMatchInProgress = false;
      });
      return;
    }

    // Get the teams
    final teamA = teamsNotifier.getTeam(teamIds[0]);
    final teamB = teamsNotifier.getTeam(teamIds[1]);
    if (teamA == null || teamB == null) {
      setState(() {
        _currentMatch = null;
        _teamA = null;
        _teamB = null;
        _isMatchInProgress = false;
      });
      return;
    }

    setState(() {
      _teamA = teamA;
      _teamB = teamB;
      _isMatchInProgress = false;
    });

    // Create the match
    matchesNotifier
        .createMatch(
      teamA: teamA,
      teamB: teamB,
    )
        .then((match) {
      setState(() {
        _currentMatch = match;
      });
    });
  }

  void _startMatch() {
    if (_currentMatch == null || _teamA == null || _teamB == null) return;

    _tournament.startMatch(_currentMatch!);
    tournamentNotifier.updateTournament(_tournament);

    setState(() {
      _isMatchInProgress = true;
    });

    // Navigate to scoreboard
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreboardScreen(
          match: _currentMatch!,
          teamA: _teamA!,
          teamB: _teamB!,
          gameConfig: _tournament.config,
          onMatchComplete: _onMatchComplete,
          tournamentName: _tournament.name,
        ),
      ),
    );
  }

  void _onMatchComplete() {
    if (_currentMatch == null) return;

    // Get the updated match
    final updatedMatch = matchesNotifier.getMatch(_currentMatch!.id);
    if (updatedMatch == null || !updatedMatch.isComplete) return;

    // Process match result
    tournamentNotifier
        .processMatchResult(
      _tournament.id,
      updatedMatch.id,
      teamsNotifier,
      matchesNotifier,
    )
        .then((_) {
      // Get the updated tournament
      final updatedTournament =
          tournamentNotifier.getTournament(_tournament.id);
      if (updatedTournament != null) {
        setState(() {
          _tournament = updatedTournament;
          _isMatchInProgress = false;
        });
      }

      // Show match summary
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MatchSummaryScreen(
              match: updatedMatch,
              tournament: _tournament,
              onContinue: () {
                Navigator.pop(context);
                _loadNextMatch();
              },
            ),
          ),
        );
      }
    });
  }

  Widget _buildBody() {
    if (teamsNotifier.isLoading || tournamentNotifier.isLoading) {
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

    if (tournamentNotifier.error != null) {
      return Center(
        child: Text(
          'Error loading tournament: ${tournamentNotifier.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final teams = teamsNotifier.teams;
    final tournaments = tournamentNotifier.tournaments;

    // Get the latest tournament data
    final latestTournament = tournaments[_tournament.id];
    if (latestTournament != null) {
      _tournament = latestTournament;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildTournamentContent(teams),
    );
  }

  Widget _buildTournamentContent(Map<String, Team> teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTournamentInfo(),
        const SizedBox(height: 24),
        _buildCurrentMatch(teams),
        const SizedBox(height: 24),
        _buildTeamQueue(teams),
        const SizedBox(height: 24),
        _buildMatchHistory(teams),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tournament.name,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTournament,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildTournamentInfo() {
    final matchesPlayed = _tournament.matchIds.length;
    final matchesRemaining = _tournament.config.totalMatches != null
        ? _tournament.config.totalMatches! - matchesPlayed
        : null;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Torneio',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Partidas Jogadas', '$matchesPlayed'),
            if (matchesRemaining != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Partidas Restantes', '$matchesRemaining'),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              'Vitórias para Espera',
              '${_tournament.config.winsForWaitingMode}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Status',
              _tournament.isComplete ? 'Finalizado' : 'Em andamento',
              valueColor: _tournament.isComplete ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentMatch(Map<String, Team> teams) {
    if (_tournament.isComplete) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Torneio Finalizado!',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetTournament,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Reiniciar Torneio',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_teamA == null || _teamB == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.sports_score, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nenhuma partida disponível',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Próxima Partida',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamColumn(_teamA!),
                Text(
                  'VS',
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTeamColumn(_teamB!),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isMatchInProgress ? null : _startMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isMatchInProgress ? 'Partida em Andamento' : 'Iniciar Partida',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(Team team) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
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
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            team.emoji ?? '🏆',
                            style: const TextStyle(fontSize: 24),
                          );
                        },
                      ),
                    )
                  : Text(
                      team.emoji ?? '🏆',
                      style: const TextStyle(fontSize: 24),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            team.name,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Vitórias: ${team.wins}',
            style: GoogleFonts.roboto(
              fontSize: 12,
            ),
          ),
          if (team.consecutiveWins > 0) ...[
            Text(
              'Sequência: ${team.consecutiveWins}',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (team.isWaiting) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Em Espera',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamQueue(Map<String, Team> teams) {
    final queueTeamIds = _tournament.queueIds;
    final waitingTeamId = _tournament.waitingTeamId;

    if (queueTeamIds.isEmpty && waitingTeamId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fila de Times',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (waitingTeamId != null) ...[
              Text(
                'Time em Espera',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _buildTeamList([waitingTeamId], teams, isWaiting: true),
              const SizedBox(height: 16),
            ],
            if (queueTeamIds.isNotEmpty) ...[
              Text(
                'Próximos na Fila',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTeamList(queueTeamIds, teams),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(List<String> teamIds, Map<String, Team> teams,
      {bool isWaiting = false}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: teamIds.length,
      itemBuilder: (context, index) {
        final teamId = teamIds[index];
        final team = teams[teamId];
        if (team == null) return const SizedBox.shrink();

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
          subtitle: Text(
            'Vitórias: ${team.wins} | Sequência: ${team.consecutiveWins}',
            style: GoogleFonts.roboto(
              fontSize: 12,
            ),
          ),
          trailing: isWaiting
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Em Espera',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
              : Text(
                  '${index + 1}º',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMatchHistory(Map<String, Team> teams) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Histórico de Partidas',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMatchHistoryContent(teams),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHistoryContent(Map<String, Team> teams) {
    if (matchesNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (matchesNotifier.error != null) {
      return const Center(child: Text('Erro ao carregar partidas'));
    }

    final matches = matchesNotifier.matches;
    final historyMatches = _tournament.matchIds
        .map((matchId) => matches[matchId])
        .where((match) => match != null)
        .toList()
        .reversed
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historyMatches.length,
      itemBuilder: (context, index) {
        final match = historyMatches[index]!;
        final teamA = teams[match.teamAId];
        final teamB = teams[match.teamBId];
        if (teamA == null || teamB == null) {
          return const SizedBox.shrink();
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  teamA.name,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: match.winnerId == teamA.id ? Colors.green : null,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${match.teamAScore} - ${match.teamBScore}',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  teamB.name,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: match.winnerId == teamB.id ? Colors.green : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: match.endTime != null
              ? Center(
                  child: Text(
                    'Duração: ${_formatDuration(match.endTime!.difference(match.startTime))}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _resetTournament() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Torneio'),
        content: const Text(
            'Tem certeza que deseja reiniciar o torneio? Todas as estatísticas serão mantidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              tournamentNotifier
                  .resetTournament(
                _tournament.id,
                teamsNotifier,
              )
                  .then((_) {
                _loadNextMatch();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}
