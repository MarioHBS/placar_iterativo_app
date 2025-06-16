import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/services/tts_service.dart';
import 'package:placar_iterativo_app/services/audio_service.dart';
import 'package:placar_iterativo_app/widgets/animated_widgets.dart';

class TournamentRankingScreen extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback? onClose;

  const TournamentRankingScreen({
    super.key,
    required this.tournament,
    this.onClose,
  });

  @override
  State<TournamentRankingScreen> createState() => _TournamentRankingScreenState();
}

class _TournamentRankingScreenState extends State<TournamentRankingScreen>
    with TickerProviderStateMixin {
  late TeamsNotifier teamsNotifier;
  late TtsService _ttsService;
  late AudioService _audioService;
  late AnimationController _celebrationController;
  late AnimationController _trophyController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _trophyAnimation;
  bool _hasAnnouncedChampion = false;

  @override
  void initState() {
    super.initState();
    teamsNotifier = Modular.get<TeamsNotifier>();
    _ttsService = TtsService();
    _audioService = AudioService();
    
    // Initialize animations
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _trophyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trophyController,
      curve: Curves.bounceOut,
    ));
    
    // Start animations
    _startCelebration();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  void _startCelebration() async {
    // Start trophy animation
    _trophyController.forward();
    
    // Wait a bit then start celebration animation
    await Future.delayed(const Duration(milliseconds: 500));
    _celebrationController.forward();
    
    // Announce champion after animations start
    await Future.delayed(const Duration(milliseconds: 800));
    _announceChampion();
  }

  void _announceChampion() async {
    if (_hasAnnouncedChampion) return;
    _hasAnnouncedChampion = true;
    
    final champion = _getChampion();
    if (champion != null) {
      await _announceTournamentChampion(champion.name, widget.tournament.name);
      
      // Play celebration sound after TTS
      await Future.delayed(const Duration(seconds: 4));
      await _audioService.playCelebrationSound();
    }
  }

  Future<void> _announceTournamentChampion(String teamName, String tournamentName) async {
    // Use the new method specifically for tournament champions
    await _ttsService.announceTournamentChampion(teamName, tournamentName);
  }

  Team? _getChampion() {
    final rankedTeams = _getRankedTeams();
    return rankedTeams.isNotEmpty ? rankedTeams.first : null;
  }

  List<Team> _getRankedTeams() {
    if (teamsNotifier.isLoading || teamsNotifier.error != null) {
      return [];
    }

    final tournamentTeams = widget.tournament.teamIds
        .map((id) => teamsNotifier.teams[id])
        .where((team) => team != null)
        .cast<Team>()
        .toList();

    // Sort teams by wins (descending), then by win rate (descending)
    tournamentTeams.sort((a, b) {
      // First, compare by wins
      final winsComparison = b.wins.compareTo(a.wins);
      if (winsComparison != 0) return winsComparison;
      
      // If wins are equal, compare by win rate
      final winRateComparison = b.winRate.compareTo(a.winRate);
      if (winRateComparison != 0) return winRateComparison;
      
      // If win rates are equal, compare by consecutive wins in this tournament
      return b.getTournamentConsecutiveWins(widget.tournament.id)
          .compareTo(a.getTournamentConsecutiveWins(widget.tournament.id));
    });

    return tournamentTeams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ranking Final - ${widget.tournament.name}',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _celebrationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.amber.withOpacity(0.3 * _celebrationAnimation.value),
                  Colors.orange.withOpacity(0.2 * _celebrationAnimation.value),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
            child: _buildContent(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (teamsNotifier.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    if (teamsNotifier.error != null) {
      return Center(
        child: Text(
          'Erro ao carregar times: ${teamsNotifier.error}',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      );
    }

    final rankedTeams = _getRankedTeams();
    if (rankedTeams.isEmpty) {
      return Center(
        child: Text(
          'Nenhum time encontrado',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Champion Section
          _buildChampionSection(rankedTeams.first),
          const SizedBox(height: 32),
          
          // Ranking Section
          _buildRankingSection(rankedTeams),
          
          const SizedBox(height: 32),
          
          // Close Button
          ElevatedButton(
            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'Fechar',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionSection(Team champion) {
    return AnimatedBuilder(
      animation: _trophyAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _trophyAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.8),
                  Colors.orange.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Trophy Icon
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                
                // Champion Title
                Text(
                  'CAMPEÃO',
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Team Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Team Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: champion.color.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Center(
                        child: champion.imagePath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(champion.imagePath!),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      champion.emoji ?? '🏆',
                                      style: const TextStyle(fontSize: 32),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                champion.emoji ?? '🏆',
                                style: const TextStyle(fontSize: 32),
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Team Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            champion.name,
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vitórias: ${champion.wins}',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Taxa de Vitória: ${champion.winRate.toStringAsFixed(1)}%',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          if (champion.getTournamentConsecutiveWins(widget.tournament.id) > 0)
                            Text(
                              'Sequência: ${champion.getTournamentConsecutiveWins(widget.tournament.id)}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingSection(List<Team> rankedTeams) {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _celebrationAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Ranking Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Ranking Final',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Ranking List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rankedTeams.length,
                  itemBuilder: (context, index) {
                    final team = rankedTeams[index];
                    final position = index + 1;
                    final isChampion = position == 1;
                    
                    return _buildRankingItem(team, position, isChampion);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingItem(Team team, int position, bool isChampion) {
    Color positionColor;
    String positionEmoji;
    
    switch (position) {
      case 1:
        positionColor = Colors.amber;
        positionEmoji = '🥇';
        break;
      case 2:
        positionColor = Colors.grey.shade400;
        positionEmoji = '🥈';
        break;
      case 3:
        positionColor = Colors.orange.shade700;
        positionEmoji = '🥉';
        break;
      default:
        positionColor = Colors.white;
        positionEmoji = '$position°';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isChampion 
            ? Colors.amber.withOpacity(0.2) 
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isChampion 
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positionColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: positionColor, width: 2),
            ),
            child: Center(
              child: Text(
                position <= 3 ? positionEmoji : '$position°',
                style: GoogleFonts.roboto(
                  fontSize: position <= 3 ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: positionColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Team Avatar
          Container(
            width: 50,
            height: 50,
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
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            team.emoji ?? '🏆',
                            style: const TextStyle(fontSize: 20),
                          );
                        },
                      ),
                    )
                  : Text(
                      team.emoji ?? '🏆',
                      style: const TextStyle(fontSize: 20),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Vitórias: ${team.wins}',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Taxa: ${team.winRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (team.getTournamentConsecutiveWins(widget.tournament.id) > 0)
                  Text(
                    'Sequência: ${team.getTournamentConsecutiveWins(widget.tournament.id)}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}