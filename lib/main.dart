import 'package:flutter/material.dart';

import 'controllers/robot_controller.dart';
import 'navigation/app_shell.dart';
import 'services/product_session.dart';

void main() {
  runApp(const QingQiongApp());
}

class QingQiongApp extends StatelessWidget {
  const QingQiongApp({super.key, this.controller, this.session});

  final RobotController? controller;
  final ProductSession? session;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF176B87);
    return MaterialApp(
      title: '清穹无人清扫车',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F8),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: AppShell(controller: controller, session: session),
    );
  }
}
