import 'package:flutter/material.dart';
import 'src/core/services/audio_service.dart';           // ← добавь
import 'src/features/lobby/presentation/screens/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService().init();           // только инициализация, без play
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Autobattle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LobbyScreen(),
    );
  }
}