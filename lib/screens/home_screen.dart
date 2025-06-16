import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/theme_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/utils/responsive_utils.dart';
import 'package:placar_iterativo_app/widgets/animated_widgets.dart';

import 'game_config_screen.dart';
import 'teams_screen.dart';
import 'tournament_screen.dart';
import 'scoreboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ThemeNotifier themeNotifier;
  late TeamsNotifier teamsNotifier;
  late TournamentNotifier tournamentNotifier;
  late MatchesNotifier matchesNotifier;

  @override
  void initState() {
    super.initState();
    themeNotifier = Modular.get<ThemeNotifier>();
    teamsNotifier = Modular.get<TeamsNotifier>();
    tournamentNotifier = Modular.get<TournamentNotifier>();
    matchesNotifier = Modular.get<MatchesNotifier>();
    themeNotifier.addListener(_onThemeChanged);
    teamsNotifier.addListener(_onTeamsChanged);
    tournamentNotifier.addListener(_onTournamentsChanged);
    matchesNotifier.addListener(_onMatchesChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    teamsNotifier.removeListener(_onTeamsChanged);
    tournamentNotifier.removeListener(_onTournamentsChanged);
    matchesNotifier.removeListener(_onMatchesChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onTeamsChanged() {
    setState(() {});
  }

  void _onTournamentsChanged() {
    setState(() {});
  }

  void _onMatchesChanged() {
    setState(() {});
  }

  void _resumeActiveMatch() {
    final activeMatch = matchesNotifier.getActiveMatch();
    if (activeMatch != null) {
      final teamA = teamsNotifier.teams[activeMatch.teamAId];
      final teamB = teamsNotifier.teams[activeMatch.teamBId];

      if (teamA != null && teamB != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScoreboardScreen(
              existingMatch: activeMatch,
              teamA: teamA,
              teamB: teamB,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Placar Interativo',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => themeNotifier.toggleTheme(),
            icon: Icon(
              themeNotifier.state == ThemeMode.dark
                  ? Icons.light_mode
                  : themeNotifier.state == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
            ),
            tooltip: 'Alternar tema',
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App title
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: Center(
                    child: Text(
                      'Bem-vindo!',
                      style: GoogleFonts.bebasNeue(
                        fontSize: ResponsiveUtils.getTitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context) * 0.2),
                FadeInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: Center(
                    child: ResponsiveText(
                      'Gerencie seus jogos e torneios',
                      style: GoogleFonts.roboto(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),

                // Active match banner
                if (matchesNotifier.hasActiveMatch()) ...[
                  SlideInWidget(
                    delay: const Duration(milliseconds: 500),
                    begin: const Offset(0, -1),
                    child: _buildActiveMatchBanner(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Main actions
                SlideInWidget(
                  delay: const Duration(milliseconds: 600),
                  begin: const Offset(-1, 0),
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.sports_score,
                    label: 'Nova Partida',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameConfigScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SlideInWidget(
                  delay: const Duration(milliseconds: 800),
                  begin: const Offset(1, 0),
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.people,
                    label: 'Gerenciar Times',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeamsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Active tournaments section
                Text(
                  'Torneios Ativos',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Tournament list
                SizedBox(
                  height: 300,
                  child: _buildActiveTournamentsList(),
                ),

                // Recent tournaments section
                const SizedBox(height: 24),
                Text(
                  'Torneios Recentes',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Recent tournaments list
                SizedBox(
                  height: 120,
                  child: _buildRecentTournamentsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteTournamentDialog(
      BuildContext context, Tournament tournament) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Excluir Torneio',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tem certeza que deseja excluir o torneio "${tournament.name}"?',
                style: GoogleFonts.roboto(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta ação não pode ser desfeita. Todas as partidas e estatísticas do torneio serão perdidas.',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.roboto(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTournament(tournament);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Excluir',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTournament(Tournament tournament) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Excluindo torneio...',
                style: GoogleFonts.roboto(),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Delete the tournament
      await tournamentNotifier.deleteTournament(tournament.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Torneio "${tournament.name}" excluído com sucesso',
                  style: GoogleFonts.roboto(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erro ao excluir torneio: ${e.toString()}',
                    style: GoogleFonts.roboto(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildActiveTournamentsList() {
    if (tournamentNotifier.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tournamentNotifier.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar torneios',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tournamentNotifier.error!,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final activeTournaments = tournamentNotifier.getActiveTournaments();

    if (activeTournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum torneio ativo',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um novo torneio em "Nova Partida"',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: activeTournaments.length,
      itemBuilder: (context, index) {
        final tournament = activeTournaments[index];
        return SlideInWidget(
          delay: Duration(milliseconds: 200 + (index * 100)),
          begin: const Offset(0, 1),
          child: _buildTournamentCard(context, tournament),
        );
      },
    );
  }

  Widget _buildRecentTournamentsList() {
    if (tournamentNotifier.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final completedTournaments =
        tournamentNotifier.getRecentTournaments(limit: 5);

    if (completedTournaments.isEmpty) {
      return Center(
        child: Text(
          'Nenhum torneio finalizado',
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: completedTournaments.length,
      itemBuilder: (context, index) {
        final tournament = completedTournaments[index];
        return SlideInWidget(
          delay: Duration(milliseconds: 200 + (index * 100)),
          begin: const Offset(1, 0),
          child: _buildRecentTournamentCard(context, tournament),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedButton(
      onPressed: onTap,
      backgroundColor: color,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.isMobile(context) ? 16 : 20,
        horizontal: 24,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: ResponsiveUtils.getIconSize(context),
          ),
          const SizedBox(width: 12),
          ResponsiveText(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            mobileFontSize: 16,
            tabletFontSize: 18,
            desktopFontSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentScreen(tournament: tournament),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ativo',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteTournamentDialog(context, tournament);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir torneio'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Partidas: ${tournament.matchIds.length}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Times: ${tournament.teamIds.length}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!teamsNotifier.isLoading && teamsNotifier.error == null) ...[
                Builder(
                  builder: (context) {
                    // Get the top teams
                    final tournamentTeams = tournament.teamIds
                        .map((id) => teamsNotifier.teams[id])
                        .where((team) => team != null)
                        .toList();

                    tournamentTeams.sort((a, b) => b!.wins.compareTo(a!.wins));

                    return Row(
                      children: [
                        Text(
                          'Líder: ',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tournamentTeams.isNotEmpty) ...[
                          Text(
                            '${tournamentTeams.first!.name} (${tournamentTeams.first!.wins} vitórias)',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: tournamentTeams.first!.color,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTournamentCard(
      BuildContext context, Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentScreen(tournament: tournament),
          ),
        ),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Partidas: ${tournament.matchIds.length}',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (!teamsNotifier.isLoading && teamsNotifier.error == null) ...[
                Builder(
                  builder: (context) {
                    // Find the winner (team with most wins)
                    final tournamentTeams = tournament.teamIds
                        .map((id) => teamsNotifier.teams[id])
                        .where((team) => team != null)
                        .toList();

                    tournamentTeams.sort((a, b) => b!.wins.compareTo(a!.wins));

                    return tournamentTeams.isNotEmpty
                        ? Row(
                            children: [
                              Text(
                                'Vencedor: ',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tournamentTeams.first!.name,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: tournamentTeams.first!.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox();
                  },
                ),
              ] else ...[
                const SizedBox(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMatchBanner() {
    final activeMatch = matchesNotifier.getActiveMatch();
    if (activeMatch == null) return const SizedBox();

    final teamA = teamsNotifier.teams[activeMatch.teamAId];
    final teamB = teamsNotifier.teams[activeMatch.teamBId];

    if (teamA == null || teamB == null) return const SizedBox();

    final duration = DateTime.now().difference(activeMatch.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'PARTIDA EM ANDAMENTO',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  durationText,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      teamA.name,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeMatch.teamAScore.toString(),
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      teamB.name,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeMatch.teamBScore.toString(),
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resumeActiveMatch,
              icon: const Icon(Icons.play_arrow, color: Colors.orange),
              label: Text(
                'RETOMAR PARTIDA',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
