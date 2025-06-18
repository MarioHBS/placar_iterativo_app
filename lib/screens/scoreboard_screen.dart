import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/services/tts_service.dart';

class ScoreboardScreen extends StatefulWidget {
  final Match? match;
  final Team teamA;
  final Team teamB;
  final GameConfig? gameConfig;
  final VoidCallback? onMatchComplete;
  final String? tournamentName;
  final List<Team>? nextTeamsInQueue;
  final Match? existingMatch;

  const ScoreboardScreen({
    super.key,
    this.match,
    required this.teamA,
    required this.teamB,
    this.gameConfig,
    this.onMatchComplete,
    this.tournamentName,
    this.nextTeamsInQueue,
    this.existingMatch,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  static const String _orientationLockKey = 'orientation_lock';
  static const String _lockedOrientationKey = 'locked_orientation';
  late CurrentGameNotifier currentGameNotifier;
  late MatchesNotifier matchesNotifier;
  late Timer _timer;
  final TtsService _ttsService = TtsService();
  int _elapsedSeconds = 0;
  bool _isTimeUp = false;
  bool _isOrientationLocked = false;
  bool _showOrientationMenu = false;
  Orientation? _lockedOrientation;
  late Box _settingsBox;
  late Match currentMatch;
  late GameConfig currentGameConfig;

  @override
  void initState() {
    super.initState();
    currentGameNotifier = Modular.get<CurrentGameNotifier>();
    matchesNotifier = Modular.get<MatchesNotifier>();

    // Use existing match or create new one
    if (widget.existingMatch != null) {
      currentMatch = widget.existingMatch!;
      // Calculate elapsed time from existing match
      _elapsedSeconds =
          DateTime.now().difference(currentMatch.startTime).inSeconds;
    } else if (widget.match != null) {
      currentMatch = widget.match!;
    } else {
      // Create a new match if none provided
      currentMatch = Match.create(
        teamA: widget.teamA,
        teamB: widget.teamB,
      );
    }

    // Use provided gameConfig or create a default one
    currentGameConfig = widget.gameConfig ??
        GameConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          endCondition: EndCondition.score,
          scoreLimit: 15,
          timeLimit: 1800, // 30 minutos
        );

    currentGameNotifier.addListener(_onGameStateChanged);
    matchesNotifier.addListener(_onMatchesChanged);
    _initializeTts();
    _startTimer();
    _loadOrientationSettings();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initialize();
    // Anunciar início ou retomada da partida após um pequeno delay
    Future.delayed(const Duration(seconds: 1), () {
      if (widget.existingMatch != null) {
        // Se é uma partida existente, anunciar retomada
        _ttsService.announceMatchResume();
      } else {
        // Se é uma partida nova, anunciar início
        _ttsService.announceMatchStart();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ttsService.dispose();
    currentGameNotifier.removeListener(_onGameStateChanged);
    matchesNotifier.removeListener(_onMatchesChanged);
    _saveOrientationSettings();
    _restoreDefaultOrientation();
    super.dispose();
  }

  void _onGameStateChanged() => setState(() {});

  void _onMatchesChanged() => setState(() {});

  Future<void> _loadOrientationSettings() async {
    try {
      _settingsBox = await Hive.openBox('settings');
      _isOrientationLocked =
          _settingsBox.get(_orientationLockKey, defaultValue: false);
      final savedOrientation =
          _settingsBox.get(_lockedOrientationKey, defaultValue: 'portrait');
      _lockedOrientation = savedOrientation == 'landscape'
          ? Orientation.landscape
          : Orientation.portrait;

      if (_isOrientationLocked && _lockedOrientation != null) {
        _applyOrientationLock(_lockedOrientation!);
      } else {
        _enableFullRotation();
      }
    } catch (e) {
      // Se houver erro, mantém orientação livre
      _isOrientationLocked = false;
      _enableFullRotation();
    }
  }

  Future<void> _saveOrientationSettings() async {
    try {
      await _settingsBox.put(_orientationLockKey, _isOrientationLocked);
      if (_lockedOrientation != null) {
        final orientationString = _lockedOrientation == Orientation.landscape
            ? 'landscape'
            : 'portrait';
        await _settingsBox.put(_lockedOrientationKey, orientationString);
      }
    } catch (e) {
      // Ignora erro de salvamento
    }
  }

  void _enableFullRotation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Enable fullscreen mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _applyOrientationLock(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // Enable fullscreen mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _restoreDefaultOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleOrientationLock() {
    setState(() {
      _isOrientationLocked = !_isOrientationLocked;

      if (_isOrientationLocked) {
        // Lock to current orientation
        final currentOrientation = MediaQuery.of(context).orientation;
        _lockedOrientation = currentOrientation;
        _applyOrientationLock(currentOrientation);
      } else {
        // Unlock orientation
        _enableFullRotation();
      }
    });
  }

  void _forceOrientation(Orientation orientation) {
    setState(() {
      _isOrientationLocked = true;
      _lockedOrientation = orientation;
      _applyOrientationLock(orientation);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;

        // Check if time limit is reached
        if (currentGameConfig.shouldEndByTime(_elapsedSeconds)) {
          _isTimeUp = true;
          _endMatch();
        }
      });
    });
  }

  void _incrementScore(bool isTeamA) async {
    if (isTeamA) {
      await matchesNotifier.incrementTeamAScore(currentMatch.id);
    } else {
      await matchesNotifier.incrementTeamBScore(currentMatch.id);
    }

    // Get updated match
    final updatedMatch = matchesNotifier.matches[currentMatch.id];
    if (updatedMatch == null) return;

    // Check if score limit is reached
    final isScoreLimitReached = currentGameConfig.shouldEndByScore(
        updatedMatch.teamAScore, updatedMatch.teamBScore);

    // Only announce score if limit is not reached to avoid interruption
    if (!isScoreLimitReached) {
      _ttsService.announceScore(
        teamAName: widget.teamA.name,
        teamAScore: updatedMatch.teamAScore,
        teamBName: widget.teamB.name,
        teamBScore: updatedMatch.teamBScore,
      );
    }

    // End match if score limit is reached
    if (isScoreLimitReached) {
      setState(() {});
      _endMatch();
    }
  }

  void _decrementScore(bool isTeamA) async {
    if (isTeamA) {
      await matchesNotifier.decrementTeamAScore(currentMatch.id);
    } else {
      await matchesNotifier.decrementTeamBScore(currentMatch.id);
    }
  }

  void _endMatch() {
    print('DEBUG: _endMatch called');
    print(
        'DEBUG: currentGameConfig.endCondition = ${currentGameConfig.endCondition}');
    print('DEBUG: currentMatch.id = ${currentMatch.id}');
    print('DEBUG: currentMatch.isComplete = ${currentMatch.isComplete}');

    _timer.cancel();

    // Determinar o vencedor e anunciar
    final updatedMatch = matchesNotifier.matches[currentMatch.id];
    print('DEBUG: updatedMatch found = ${updatedMatch != null}');

    if (updatedMatch != null) {
      print('DEBUG: updatedMatch.isComplete = ${updatedMatch.isComplete}');

      final winner = updatedMatch.teamAScore > updatedMatch.teamBScore
          ? widget.teamA
          : widget.teamB;

      print('DEBUG: Winner determined = ${winner.name}');

      // Anunciar o vencedor após um pequeno delay
      Future.delayed(const Duration(seconds: 2), () {
        _ttsService.announceWinner(winner.name);
      });
    }

    print('DEBUG: Calling completeMatch');
    matchesNotifier.completeMatch(currentMatch.id).then((_) {
      print('DEBUG: completeMatch completed successfully');
      if (widget.onMatchComplete != null) {
        print('DEBUG: Calling onMatchComplete callback');
        widget.onMatchComplete!();
      } else {
        print('DEBUG: No onMatchComplete callback provided');
      }
    }).catchError((error) {
      print('DEBUG: Error in completeMatch: $error');
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Match _getCurrentMatch() {
    if (!matchesNotifier.isLoading && matchesNotifier.error == null) {
      return matchesNotifier.matches[currentMatch.id] ?? currentMatch;
    }
    return currentMatch;
  }

  Color _getDividerColor() {
    // Calcula a luminância das cores dos times
    final teamALuminance = widget.teamA.color.computeLuminance();
    final teamBLuminance = widget.teamB.color.computeLuminance();

    // Se ambos os times têm cores claras (luminância > 0.5), usa uma cor escura
    if (teamALuminance > 0.5 && teamBLuminance > 0.5) {
      return Colors.black87;
    }
    // Se ambos os times têm cores escuras (luminância < 0.3), usa uma cor clara
    else if (teamALuminance < 0.3 && teamBLuminance < 0.3) {
      return Colors.white;
    }
    // Para casos mistos ou intermediários, usa branco como padrão
    else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _getCurrentMatch();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          isLandscape
              ? _buildLandscapeLayout(match, screenWidth, screenHeight)
              : _buildPortraitLayout(match, screenWidth, screenHeight),

          // Orientation controls
          _buildOrientationControls(),

          // Tournament menu (only show if tournament name is provided)
          if (widget.tournamentName != null) _buildTournamentMenu(),
        ],
      ),
    );
  }

  Widget _buildTournamentMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Positioned(
      // Paisagem: centro horizontal, Retrato: lado esquerdo
      left: isLandscape ? (screenWidth / 2) - 24 : 8,
      // Paisagem: parte inferior, Retrato: centro vertical
      top: isLandscape ? screenHeight - 48 : screenHeight / 2 - 24,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 24,
          ),
          onPressed: _showTournamentDialog,
          tooltip: 'Informações do Torneio',
        ),
      ),
    );
  }

  void _showTournamentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.sports_soccer, color: Colors.green),
              const SizedBox(width: 8),
              Text(widget.tournamentName!),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Próximos times na fila:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.nextTeamsInQueue != null &&
                  widget.nextTeamsInQueue!.isNotEmpty)
                ...widget.nextTeamsInQueue!
                    .take(2)
                    .map((team) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: team.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList()
              else
                const Text(
                  'Nenhum time na fila',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrientationControls() {
    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main orientation button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showOrientationMenu = !_showOrientationMenu;
                });
              },
              icon: Icon(
                Icons.screen_rotation,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Opções de Orientação',
            ),
          ),
          // Dropdown menu
          if (_showOrientationMenu)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Portrait option
                  _buildOrientationOption(
                    icon: Icons.stay_current_portrait,
                    label: 'Retrato',
                    isActive: MediaQuery.of(context).orientation ==
                        Orientation.portrait,
                    onTap: () {
                      _forceOrientation(Orientation.portrait);
                      setState(() {
                        _showOrientationMenu = false;
                      });
                    },
                  ),
                  // Landscape option
                  _buildOrientationOption(
                    icon: Icons.stay_current_landscape,
                    label: 'Paisagem',
                    isActive: MediaQuery.of(context).orientation ==
                        Orientation.landscape,
                    onTap: () {
                      _forceOrientation(Orientation.landscape);
                      setState(() {
                        _showOrientationMenu = false;
                      });
                    },
                  ),
                  // Lock/unlock option
                  _buildOrientationOption(
                    icon: _isOrientationLocked
                        ? Icons.screen_lock_rotation
                        : Icons.screen_rotation,
                    label: _isOrientationLocked ? 'Desbloquear' : 'Bloquear',
                    isActive: _isOrientationLocked,
                    onTap: () {
                      _toggleOrientationLock();
                      setState(() {
                        _showOrientationMenu = false;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrientationOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.white,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(Match match, double width, double height) {
    return Row(
      children: [
        Expanded(
          child: _buildTeamSection(
            team: widget.teamA,
            score: match.teamAScore,
            isTeamA: true,
            width: (width - 2) / 2,
            height: height,
          ),
        ),
        Container(
          width: 2,
          height: height,
          color: _getDividerColor(),
        ),
        Expanded(
          child: _buildTeamSection(
            team: widget.teamB,
            score: match.teamBScore,
            isTeamA: false,
            width: (width - 2) / 2,
            height: height,
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(Match match, double width, double height) {
    return Column(
      children: [
        Expanded(
          child: _buildTeamSection(
            team: widget.teamA,
            score: match.teamAScore,
            isTeamA: true,
            width: width,
            height: height / 2,
          ),
        ),
        Container(
          width: width,
          height: 2,
          color: _getDividerColor(),
        ),
        Expanded(
          child: _buildTeamSection(
            team: widget.teamB,
            score: match.teamBScore,
            isTeamA: false,
            width: width,
            height: height / 2,
          ),
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final fontSize = isLandscape ? 100.0 : 120.0;
    final teamNameSize = isLandscape ? 28.0 : 32.0;
    final emojiSize = isLandscape ? 40.0 : 48.0;

    return GestureDetector(
      onTap: () => _incrementScore(isTeamA),
      onLongPress: () => _decrementScore(isTeamA),
      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        // Movimento para baixo (delta Y positivo)
        // Movimento para cima (delta Y negativo)
        if (velocity > 0) {
          _decrementScore(isTeamA);
        } else if (velocity < 0) {
          _incrementScore(isTeamA);
        }
      },
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
                      style: TextStyle(fontSize: emojiSize),
                    ),
                  if (team.imagePath != null)
                    ClipOval(
                      child: Image.file(
                        File(team.imagePath!),
                        width: isLandscape ? 60 : 80,
                        height: isLandscape ? 60 : 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            team.emoji ?? '🏆',
                            style: TextStyle(fontSize: emojiSize),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: isLandscape ? 12 : 16),
                  // Team name
                  Text(
                    team.name,
                    style: GoogleFonts.roboto(
                      fontSize: teamNameSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isLandscape ? 16 : 24),
                  // Score
                  Text(
                    score.toString(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Timer display (only show on first team section to avoid duplication)
            if (isTeamA)
              Positioned(
                top: isLandscape ? 70 : 16,
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
                      fontSize: isLandscape ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: _isTimeUp ? Colors.red : Colors.white,
                    ),
                  ),
                ),
              ),
            // End match button (only show on second team section)
            if (!isTeamA)
              Positioned(
                bottom: 16,
                right: 16,
                child: ElevatedButton(
                  onPressed: _endMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 12 : 16,
                      vertical: isLandscape ? 6 : 8,
                    ),
                  ),
                  child: Text(
                    'Finalizar',
                    style: GoogleFonts.roboto(
                      fontSize: isLandscape ? 14 : 16,
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
