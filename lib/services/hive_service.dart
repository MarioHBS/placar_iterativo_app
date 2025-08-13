import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:placar_iterativo_app/models/game_config.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/team.dart';
import 'package:placar_iterativo_app/models/tournament.dart';

class HiveService {
  static Future<void> init({bool isTest = false}) async {
    if (!isTest) {
      await Hive.initFlutter();
    }
    registerAdapters();
  }

  static void registerAdapters() {
    Hive.registerAdapter(TeamAdapter());
    Hive.registerAdapter(GameConfigAdapter());
    Hive.registerAdapter(MatchAdapter());
    Hive.registerAdapter(TournamentAdapter());
    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(DateTimeAdapter());
    Hive.registerAdapter(GameModeAdapter());
    Hive.registerAdapter(EndConditionAdapter());
  }

  // Save a team to Hive
  static Future<void> saveTeam(Team team) async {
    final box = await Hive.openBox<Team>('teams');
    await box.put(team.id, team);
  }

  // Save a match to Hive
  static Future<void> saveMatch(Match match) async {
    final box = await Hive.openBox<Match>('matches');
    await box.put(match.id, match);
  }

  // Clear all Hive boxes
  static Future<void> clearAllBoxes() async {
    final boxNames = ['teams', 'matches', 'tournaments', 'game_config'];
    
    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
        } else {
          final box = await Hive.openBox(boxName);
          await box.clear();
          await box.close();
        }
      } catch (e) {
        // Ignore errors for boxes that don't exist
      }
    }
  }
}

// Custom adapter for Color
class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 100;

  @override
  Color read(BinaryReader reader) {
    final value = reader.readInt();
    return Color(value);
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value);
  }
}

// Custom adapter for DateTime
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final int typeId = 101;

  @override
  DateTime read(BinaryReader reader) {
    final micros = reader.readInt();
    return DateTime.fromMicrosecondsSinceEpoch(micros);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.microsecondsSinceEpoch);
  }
}
