import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/ssh_tool_screen.dart';
import 'providers/ssh_provider.dart';
import 'theme/app_theme.dart';

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
        theme: AppTheme.lightTheme,
        home: const SSHToolScreen(),
      ),
    );
  }
}
