import 'package:flutter/material.dart';
import 'src/features/lobby/presentation/screens/lobby_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LobbyScreen(),
    );
  }
}