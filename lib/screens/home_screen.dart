import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/theme_provider.dart';
import 'package:placar_iterativo_app/utils/responsive_utils.dart';
import 'package:placar_iterativo_app/widgets/animated_widgets.dart';

import 'game_config_screen.dart';
import 'teams_screen.dart';
import 'tournament_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ThemeNotifier themeNotifier;
  late TeamsNotifier teamsNotifier;

  @override
  void initState() {
    super.initState();
    themeNotifier = Modular.get<ThemeNotifier>();
    teamsNotifier = Modular.get<TeamsNotifier>();
    themeNotifier.addListener(_onThemeChanged);
    teamsNotifier.addListener(_onTeamsChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    teamsNotifier.removeListener(_onTeamsChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onTeamsChanged() {
    setState(() {});
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
                            ?.withOpacity(0.7),
                      ),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),

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
                  child: Center(
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
                  ),
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
                  child: Center(
                    child: Text(
                      'Nenhum torneio finalizado',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
}
