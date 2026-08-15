import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const QingQiongApp());
}

class QingQiongApp extends StatelessWidget {
  const QingQiongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '清穹无人清扫车',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
