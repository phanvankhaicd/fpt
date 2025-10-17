import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/ssh_provider.dart';
import '../models/ssh_connection.dart';

class ConnectionSection extends StatefulWidget {
  @override
  _ConnectionSectionState createState() => _ConnectionSectionState();
}

class _ConnectionSectionState extends State<ConnectionSection> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _keyPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _portController.text = '22';
    _keyPathController.text = _getDefaultSSHKeyPath();
  }

  String _getDefaultSSHKeyPath() {
    final homeDir =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return '$homeDir/.ssh/id_rsa';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.router,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SSH Connection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Host input with dropdown
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          hintText: 'user@server.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.computer),
                        ),
                        onChanged: (value) => provider.setHost(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final port = int.tryParse(value) ?? 22;
                          provider.setPort(port);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Key path input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keyPathController,
                        decoration: const InputDecoration(
                          labelText: 'SSH Key Path',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                        onChanged: (value) => provider.setKeyPath(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _browseForKey,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isConnecting
                          ? null
                          : () => _testConnection(provider),
                      icon: provider.isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(
                        provider.isConnecting
                            ? 'Testing...'
                            : 'Test Connection',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _saveConnection(provider),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Connection history
                if (provider.connectionHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Recent Connections',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: provider.connectionHistory.take(5).map((
                      connection,
                    ) {
                      return GestureDetector(
                        onTap: () => _loadConnection(provider, connection),
                        child: Chip(
                          label: Text(connection.displayName),
                          onDeleted: () =>
                              _deleteConnection(provider, connection),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _browseForKey() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'key', 'rsa', 'ed25519'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        _keyPathController.text = result.files.single.path!;
        Provider.of<SSHProvider>(
          context,
          listen: false,
        ).setKeyPath(result.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting key file: $e')));
    }
  }

  Future<void> _testConnection(SSHProvider provider) async {
    if (_hostController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a host')));
      return;
    }

    await provider.testConnection();
  }

  void _saveConnection(SSHProvider provider) {
    if (_hostController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host to save')),
      );
      return;
    }

    provider.saveConnection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection saved to history')),
    );
  }

  void _loadConnection(SSHProvider provider, SSHConnection connection) {
    _hostController.text = connection.host;
    _portController.text = connection.port.toString();
    _keyPathController.text = connection.keyPath;
    provider.loadConnection(connection);
  }

  void _deleteConnection(SSHProvider provider, SSHConnection connection) {
    provider.deleteConnection(connection);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _keyPathController.dispose();
    super.dispose();
  }
}
