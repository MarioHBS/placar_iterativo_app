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

    // Register adapters
    _registerAdapters();

    // Register type adapters for custom types
    _registerTypeAdapters();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(TeamAdapter());
    Hive.registerAdapter(GameConfigAdapter());
    Hive.registerAdapter(GameModeAdapter());
    Hive.registerAdapter(EndConditionAdapter());
    Hive.registerAdapter(MatchAdapter());
    Hive.registerAdapter(TournamentAdapter());
  }

  static void _registerTypeAdapters() {
    // Register adapter for Color
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(ColorAdapter());
    }

    // Register adapter for DateTime
    if (!Hive.isAdapterRegistered(101)) {
      Hive.registerAdapter(DateTimeAdapter());
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
