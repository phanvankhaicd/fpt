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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Connection and Execute sections
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Section - Left side
                    Expanded(flex: 2, child: ConnectionSection()),
                    const SizedBox(width: 8),
                    // Execute Section - Right side
                    Expanded(flex: 1, child: ExecuteSection()),
                  ],
                ),

                const SizedBox(height: 8),

                // Middle row: File Operations and Progress
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Operations Section - Left side
                    Expanded(flex: 2, child: FileOperationsSection()),
                    const SizedBox(width: 8),
                    // Progress Section - Right side
                    Expanded(flex: 1, child: ProgressSection()),
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom: Console Section - Full width
                ConsoleSection(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<SSHProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton.extended(
            onPressed: provider.canExecute && !provider.progress.isInProgress
                ? () => _executeTransfer(provider)
                : null,
            icon: provider.progress.isInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.rocket_launch),
            label: Text(
              provider.progress.isInProgress ? 'Executing...' : 'Execute',
            ),
            backgroundColor:
                provider.canExecute && !provider.progress.isInProgress
                ? Colors.green
                : Colors.grey,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Future<void> _executeTransfer(SSHProvider provider) async {
    await provider.executeTransfer();
  }
}
