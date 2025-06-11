import 'package:flutter_modular/flutter_modular.dart';
import 'package:placar_iterativo_app/providers/theme_provider.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/game_config_provider.dart';
import 'package:placar_iterativo_app/providers/current_game_provider.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';
import 'package:placar_iterativo_app/screens/home_screen.dart';
import 'package:placar_iterativo_app/screens/teams_screen.dart';
import 'package:placar_iterativo_app/screens/game_config_screen.dart';
import 'package:placar_iterativo_app/screens/backup_screen.dart';

class AppModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<ThemeNotifier>(ThemeNotifier.new);
    i.addSingleton<TeamsNotifier>(TeamsNotifier.new);
    i.addSingleton<GameConfigNotifier>(GameConfigNotifier.new);
    i.addSingleton<CurrentGameNotifier>(CurrentGameNotifier.new);
    i.addSingleton<MatchesNotifier>(MatchesNotifier.new);
    i.addSingleton<TournamentNotifier>(TournamentNotifier.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const HomeScreen());
    r.child('/teams', child: (context) => const TeamsScreen());
    r.child('/game-config', child: (context) => const GameConfigScreen());
    r.child('/backup', child: (context) => const BackupScreen());
  }
}
