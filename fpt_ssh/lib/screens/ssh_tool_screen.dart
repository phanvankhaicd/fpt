import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';
import '../widgets/connection_section.dart';
import '../widgets/file_operations_section.dart';
import '../widgets/progress_section.dart';
import '../widgets/execute_section.dart';
import '../widgets/console_section.dart';

class SSHToolScreen extends StatelessWidget {
  const SSHToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Colors.white),
            SizedBox(width: 8),
            Text('SSH File Transfer & Execute Tool'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Consumer<SSHProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SSH Connection Section
                ConnectionSection(),

                const SizedBox(height: 16),

                // File Operations Section
                FileOperationsSection(),

                const SizedBox(height: 16),

                // Progress Section
                ProgressSection(),

                const SizedBox(height: 16),

                // Execute Section
                ExecuteSection(),

                const SizedBox(height: 16),

                // Console Output Section
                ConsoleSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}
