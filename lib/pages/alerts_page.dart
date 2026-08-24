import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('告警')),
      body: const SafeArea(
        child: Center(child: Text('告警（占位）', style: TextStyle(fontSize: 18))),
      ),
    );
  }
}
