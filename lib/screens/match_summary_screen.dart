import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';

class MatchSummaryScreen extends StatefulWidget {
  final Match match;
  final Tournament? tournament;
  final VoidCallback onContinue;

  const MatchSummaryScreen({
    super.key,
    required this.match,
    this.tournament,
    required this.onContinue,
  });

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  late TeamsNotifier teamsNotifier;

  @override
  void initState() {
    super.initState();
    teamsNotifier = Modular.get<TeamsNotifier>();
    teamsNotifier.addListener(_onTeamsChanged);
  }

  void _onTeamsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    teamsNotifier.removeListener(_onTeamsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (teamsNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teamsNotifier.error != null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final teams = teamsNotifier.teams;
    final teamA = teams[widget.match.teamAId];
    final teamB = teams[widget.match.teamBId];

    if (teamA == null || teamB == null) {
      return const Center(child: Text('Erro ao carregar times'));
    }

    return _buildSummaryContent(context, teamA, teamB);
  }

  Widget _buildSummaryContent(BuildContext context, Team teamA, Team teamB) {
    final winner = widget.match.winnerId != null
        ? (widget.match.winnerId == teamA.id ? teamA : teamB)
        : null;

    final duration = widget.match.endTime != null
        ? widget.match.endTime!.difference(widget.match.startTime)
        : Duration.zero;

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top content
            Flexible(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Resumo da Partida',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Teams and Score
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTeamColumn(teamA, widget.match.teamAScore),
                        Text(
                          'VS',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildTeamColumn(teamB, widget.match.teamBScore),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Match details
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Duração',
                              '$minutes:${seconds.toString().padLeft(2, '0')}'),
                          const Divider(),
                          if (winner != null) ...[
                            _buildDetailRow('Vencedor', winner.name),
                            const Divider(),
                          ],
                          if (widget.tournament != null) ...[
                            _buildDetailRow('Torneio', widget.tournament!.name),
                            const Divider(),
                            _buildDetailRow(
                              'Partidas Restantes',
                              widget.tournament!.config.totalMatches != null
                                  ? '${widget.tournament!.config.totalMatches! - widget.tournament!.matchIds.length}'
                                  : 'Ilimitado',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom button - always visible
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.tournament != null ? 'Próxima Partida' : 'Continuar',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(Team team, int score) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team emoji or image
          if (team.emoji != null)
            Text(
              team.emoji!,
              style: const TextStyle(fontSize: 40),
            ),
          if (team.imagePath != null)
            ClipOval(
              child: Image.file(
                File(team.imagePath!),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    team.emoji ?? '🏆',
                    style: const TextStyle(fontSize: 40),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          // Team name
          Text(
            team.name,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Score
          Text(
            score.toString(),
            style: GoogleFonts.bebasNeue(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: team.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
