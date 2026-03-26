import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_menu_screen.dart';
import '../screens/game_setup_screen.dart';
import '../screens/score_calculator_screen.dart';
import '../screens/final_scores_screen.dart';
import '../screens/game_history_screen.dart';
import '../screens/game_details_screen.dart';
import '../screens/high_scores_screen.dart';
import '../screens/cleanup_screen.dart';
import '../screens/stats_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'main-menu',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/setup',
      name: 'setup',
      builder: (context, state) => const GameSetupScreen(),
    ),
    GoRoute(
      path: '/calculator',
      name: 'calculator',
      builder: (context, state) => const ScoreCalculatorScreen(),
    ),
    GoRoute(
      path: '/final-scores',
      name: 'final-scores',
      builder: (context, state) => const FinalScoresScreen(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const GameHistoryScreen(),
    ),
    GoRoute(
      path: '/game-details/:id',
      name: 'game-details',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return GameDetailsScreen(gameId: id);
      },
    ),
    GoRoute(
      path: '/highscores',
      name: 'highscores',
      builder: (context, state) => const HighScoresScreen(),
    ),
    GoRoute(
      path: '/cleanup',
      name: 'cleanup',
      builder: (context, state) => const CleanupScreen(),
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (context, state) => const StatsScreen(),
    ),
  ],
);
