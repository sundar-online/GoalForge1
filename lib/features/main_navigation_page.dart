import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection_container.dart';
import '../core/widgets/bottom_nav_bar.dart';
import 'dashboard/presentation/bloc/dashboard_bloc.dart';
import 'dashboard/presentation/bloc/dashboard_event.dart';
import 'dashboard/presentation/pages/home_page.dart';
import 'goals/presentation/bloc/goals_bloc.dart';
import 'goals/presentation/bloc/goals_event.dart';
import 'goals/presentation/pages/goals_page.dart';
import 'habits/presentation/bloc/habits_bloc.dart';
import 'habits/presentation/bloc/habits_event.dart';
import 'tasks/presentation/bloc/tasks_bloc.dart';
import 'tasks/presentation/bloc/tasks_event.dart';
import 'tasks/presentation/pages/today_forge_page.dart';
import 'logs/presentation/bloc/notes_bloc.dart';
import 'logs/presentation/bloc/notes_event.dart';
import 'logs/presentation/pages/system_logs_page.dart';
import 'events/presentation/bloc/events_bloc.dart';
import 'events/presentation/bloc/events_event.dart';
import 'focus/presentation/bloc/focus_bloc.dart';
import 'focus/presentation/bloc/focus_event.dart';
import 'focus/presentation/pages/focus_session_page.dart';
import 'analytics/presentation/bloc/analytics_bloc.dart';
import 'analytics/presentation/bloc/analytics_event.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const GoalsPage(),
      const TodayForgePage(),
      const SystemLogsPage(),
      const FocusSessionPage(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DashboardBloc>()..add(SubscribeToStreams())),
        BlocProvider(create: (_) => sl<GoalsBloc>()..add(SubscribeToGoals())),
        BlocProvider(create: (_) => sl<HabitsBloc>()..add(SubscribeToHabits())),
        BlocProvider(create: (_) => sl<TasksBloc>()..add(SubscribeToTasks())),
        BlocProvider(create: (_) => sl<NotesBloc>()..add(SubscribeToNotes())),
        BlocProvider(create: (_) => sl<EventsBloc>()..add(SubscribeToEvents())),
        BlocProvider(create: (_) => sl<FocusBloc>()..add(SubscribeToFocus())),
        BlocProvider(create: (_) => sl<AnalyticsBloc>()..add(SubscribeToAnalytics())),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
