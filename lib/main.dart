import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
    return MaterialApp(
      title: 'Superhero Recognizer',
      theme: ThemeData.light(),
      home: const MainScreen(),
    );
  }
}
