import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/ssh_tool_screen.dart';
import 'providers/ssh_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SSHProvider(),
      child: MaterialApp(
        title: 'SSH File Transfer Tool',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SSHToolScreen(),
      ),
    );
  }
}
