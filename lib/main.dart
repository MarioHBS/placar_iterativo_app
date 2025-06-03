import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:placar_iterativo_app/app_module.dart';
import 'package:placar_iterativo_app/providers/theme_provider.dart';
import 'package:placar_iterativo_app/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Hive e registra os adaptadores
  await HiveService.init();

  // Configura a orientação da tela para permitir ambas as orientações
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(ModularApp(module: AppModule(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Modular.get<ThemeNotifier>();

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Placar Interativo',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeNotifier.state,
          routerConfig: Modular.routerConfig,
        );
      },
    );
  }
}
