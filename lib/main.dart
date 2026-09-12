import 'package:flutter/material.dart';

import 'controllers/robot_controller.dart';
import 'navigation/app_shell.dart';
import 'services/product_session.dart';
import 'theme/app_design.dart';

void main() {
  runApp(const QingQiongApp());
}

class QingQiongApp extends StatelessWidget {
  const QingQiongApp({super.key, this.controller, this.session});

  final RobotController? controller;
  final ProductSession? session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '清穹无人清扫车',
      debugShowCheckedModeBanner: false,
      theme: AppDesign.theme(),
      home: AppShell(controller: controller, session: session),
    );
  }
}
