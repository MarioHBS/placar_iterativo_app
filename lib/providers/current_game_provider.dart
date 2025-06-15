import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:placar_iterativo_app/models/match.dart';
import 'package:placar_iterativo_app/models/tournament.dart';
import 'package:placar_iterativo_app/providers/matches_provider.dart';
import 'package:placar_iterativo_app/providers/teams_provider.dart';
import 'package:placar_iterativo_app/providers/tournament_provider.dart';

enum GameState {
  idle,
  playing,
  paused,
  finished,
}

class CurrentGameNotifier extends ChangeNotifier {
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  GameState _gameState = GameState.idle;
  bool _isLoading = false;
  String? _error;

  // Getters
  GameState get gameState => _gameState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get elapsedSeconds => _elapsedSeconds;



  // Start a tournament game
  Future<void> startTournamentGame({
    required Tournament tournament,
    required TournamentNotifier tournamentNotifier,
    required TeamsNotifier teamsNotifier,
    required MatchesNotifier matchesNotifier,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Start the next match in the tournament
      final match = await tournamentNotifier.startNextMatch(
        tournament.id,
        teamsNotifier,
        matchesNotifier,
      );

      if (match == null) {
        _gameState = GameState.idle;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Start the timer
      _startTimer();

      // Update the state
      _gameState = GameState.playing;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pause the current game
  void pauseGame() {
    _stopTimer();
    _gameState = GameState.paused;
    notifyListeners();
  }

  // Resume the current game
  void resumeGame() {
    _startTimer();
    _gameState = GameState.playing;
    notifyListeners();
  }

  // End the current game
  Future<void> endGame({
    required Match match,
    required MatchesNotifier matchesNotifier,
    Tournament? tournament,
    TournamentNotifier? tournamentNotifier,
    TeamsNotifier? teamsNotifier,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Stop the timer
      _stopTimer();

      // Complete the match
      await matchesNotifier.completeMatch(match.id);

      // Process the match result if in tournament mode
      if (tournament != null &&
          tournamentNotifier != null &&
          teamsNotifier != null) {
        await tournamentNotifier.processMatchResult(
          tournament.id,
          match.id,
          teamsNotifier,
          matchesNotifier,
        );
      }

      // Reset the elapsed time
      _elapsedSeconds = 0;

      // Update the state
      _gameState = GameState.finished;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset the current game state
  void resetGameState() {
    _stopTimer();
    _elapsedSeconds = 0;
    _gameState = GameState.idle;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Start the game timer
  void _startTimer() {
    _stopTimer(); // Ensure any existing timer is stopped
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners(); // Notify listeners when elapsed time changes
    });
  }

  // Stop the game timer
  void _stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  // Save current game state when navigating away
  void saveGameState() {
    if (_gameState == GameState.playing || _gameState == GameState.paused) {
      // Game state is automatically persisted through MatchesNotifier
      // This method can be used for additional state persistence if needed
    }
  }

  // Restore game state when returning to the app
  Future<void> restoreGameState() async {
    final matchesNotifier = Modular.get<MatchesNotifier>();
    final activeMatch = matchesNotifier.getActiveMatch();
    
    if (activeMatch != null) {
      // Calculate elapsed time from the match start time
      final elapsed = DateTime.now().difference(activeMatch.startTime).inSeconds;
      _elapsedSeconds = elapsed;
      
      // Set state to playing if there's an active match
      _gameState = GameState.playing;
      _startTimer();
      notifyListeners();
    }
  }

  // Check if there's an active game that can be resumed
  bool canResumeGame() {
    final matchesNotifier = Modular.get<MatchesNotifier>();
    return matchesNotifier.hasActiveMatch();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
