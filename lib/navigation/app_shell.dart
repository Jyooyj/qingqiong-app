import 'package:flutter/material.dart';

import '../controllers/robot_controller.dart';
import '../pages/home_page.dart';
import '../pages/tasks_page.dart';
import '../pages/map_page.dart';
import '../pages/alerts_page.dart';
import '../pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.controller});

  final RobotController? controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      HomePage(
        controller: widget.controller,
        onNavigateToTasks: () => setState(() => _index = 1),
        onNavigateToAlerts: () => setState(() => _index = 3),
      ),
      const TasksPage(),
      const MapPage(),
      const AlertsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: children),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.assignment), label: '任务'),
          NavigationDestination(icon: Icon(Icons.map), label: '地图'),
          NavigationDestination(icon: Icon(Icons.notifications), label: '告警'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
