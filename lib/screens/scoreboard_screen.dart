import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';

class ScoreboardScreen extends StatefulWidget {
  final Match match;
  final Team teamA;
  final Team teamB;
  final GameConfig gameConfig;
  final VoidCallback? onMatchComplete;

  const ScoreboardScreen({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
    required this.gameConfig,
    this.onMatchComplete,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late CurrentGameNotifier currentGameNotifier;
  late MatchesNotifier matchesNotifier;
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _isTimeUp = false;
  bool _isScoreReached = false;

  @override
  void initState() {
    super.initState();
    currentGameNotifier = Modular.get<CurrentGameNotifier>();
    matchesNotifier = Modular.get<MatchesNotifier>();
    currentGameNotifier.addListener(_onGameStateChanged);
    matchesNotifier.addListener(_onMatchesChanged);
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    currentGameNotifier.removeListener(_onGameStateChanged);
    matchesNotifier.removeListener(_onMatchesChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    setState(() {});
  }

  void _onMatchesChanged() {
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;

        // Check if time limit is reached
        if (widget.gameConfig.shouldEndByTime(_elapsedSeconds)) {
          _isTimeUp = true;
          _endMatch();
        }
      });
    });
  }

  void _incrementScore(bool isTeamA) async {
    if (isTeamA) {
      await matchesNotifier.incrementTeamAScore(widget.match.id);
    } else {
      await matchesNotifier.incrementTeamBScore(widget.match.id);
    }

    // Get the updated match
    final updatedMatch = matchesNotifier.matches[widget.match.id];
    if (updatedMatch == null) return;

    // Check if score limit is reached
    if (widget.gameConfig
        .shouldEndByScore(updatedMatch.teamAScore, updatedMatch.teamBScore)) {
      setState(() {
        _isScoreReached = true;
      });
      _endMatch();
    }
  }

  void _decrementScore(bool isTeamA) async {
    if (isTeamA) {
      await matchesNotifier.decrementTeamAScore(widget.match.id);
    } else {
      await matchesNotifier.decrementTeamBScore(widget.match.id);
    }
  }

  void _endMatch() {
    _timer.cancel();

    matchesNotifier.completeMatch(widget.match.id).then((_) {
      if (widget.onMatchComplete != null) {
        widget.onMatchComplete!();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Match _getCurrentMatch() {
    if (!matchesNotifier.isLoading && matchesNotifier.error == null) {
      return matchesNotifier.matches[widget.match.id] ?? widget.match;
    }
    return widget.match;
  }

  @override
  Widget build(BuildContext context) {
    final match = _getCurrentMatch();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(match, screenWidth, screenHeight)
            : _buildPortraitLayout(match, screenWidth, screenHeight),
      ),
    );
  }

  Widget _buildLandscapeLayout(Match match, double width, double height) {
    return Row(
      children: [
        _buildTeamSection(
          team: widget.teamA,
          score: match.teamAScore,
          isTeamA: true,
          width: width / 2,
          height: height,
        ),
        _buildTeamSection(
          team: widget.teamB,
          score: match.teamBScore,
          isTeamA: false,
          width: width / 2,
          height: height,
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(Match match, double width, double height) {
    return Column(
      children: [
        _buildTeamSection(
          team: widget.teamA,
          score: match.teamAScore,
          isTeamA: true,
          width: width,
          height: height / 2,
        ),
        _buildTeamSection(
          team: widget.teamB,
          score: match.teamBScore,
          isTeamA: false,
          width: width,
          height: height / 2,
        ),
      ],
    );
  }

  Widget _buildTeamSection({
    required Team team,
    required int score,
    required bool isTeamA,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      onTap: () => _incrementScore(isTeamA),
      onLongPress: () => _decrementScore(isTeamA),
      child: Container(
        width: width,
        height: height,
        color: team.color.withOpacity(0.8),
        child: Stack(
          children: [
            // Team name and score
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Team emoji or image
                  if (team.emoji != null)
                    Text(
                      team.emoji!,
                      style: const TextStyle(fontSize: 48),
                    ),
                  if (team.imagePath != null)
                    Image.asset(
                      team.imagePath!,
                      width: 80,
                      height: 80,
                    ),
                  const SizedBox(height: 16),
                  // Team name
                  Text(
                    team.name,
                    style: GoogleFonts.roboto(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Score
                  Text(
                    score.toString(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Timer display
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatTime(_elapsedSeconds),
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isTimeUp ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
            // End match button
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _endMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Finalizar',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
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
}
