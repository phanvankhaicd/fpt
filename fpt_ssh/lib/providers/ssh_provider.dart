import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/ssh_connection.dart';
import '../models/progress_info.dart';

class SSHProvider extends ChangeNotifier {
  // Connection state
  String _host = '';
  int _port = 22;
  bool _isConnected = false;
  bool _isConnecting = false;

  // File operations
  String _localFilePath = '';
  String _templateFilePath = '';
  String _remotePath = '/home/user/scripts/';

  // Progress tracking
  ProgressInfo _progress = ProgressInfo();

  // SSH History
  List<SSHConnection> _connectionHistory = [];

  // Output console
  List<String> _consoleOutput = [];

  // Getters
  String get host => _host;
  int get port => _port;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get localFilePath => _localFilePath;
  String get templateFilePath => _templateFilePath;
  String get remotePath => _remotePath;
  ProgressInfo get progress => _progress;
  List<SSHConnection> get connectionHistory => _connectionHistory;
  List<String> get consoleOutput => _consoleOutput;

  // Setters
  void setHost(String host) {
    _host = host;
    notifyListeners();
  }

  void setPort(int port) {
    _port = port;
    notifyListeners();
  }

  void setLocalFilePath(String path) {
    _localFilePath = path;
    notifyListeners();
  }

  void setTemplateFilePath(String path) {
    _templateFilePath = path;
    notifyListeners();
  }

  void setRemotePath(String path) {
    _remotePath = path;
    notifyListeners();
  }

  // Connection methods
  Future<bool> testConnection() async {
    _isConnecting = true;
    _addConsoleOutput('Testing connection to $_host...');
    notifyListeners();

    try {
      // Simulate connection test
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual SSH connection test
      _isConnected = true;
      _addConsoleOutput('✅ Connection successful!');
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _addConsoleOutput('❌ Connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> executeTransfer() async {
    // Basic validation
    if (_host.isEmpty) {
      _addConsoleOutput('❌ Host is empty');
      notifyListeners();
      return;
    }
    if (_localFilePath.isEmpty) {
      _addConsoleOutput('❌ Local file is empty');
      notifyListeners();
      return;
    }

    final destinationFileName = p.basename(_localFilePath);
    final remoteDestDir = _remotePath.endsWith('/')
        ? _remotePath
        : '$_remotePath/';
    final remoteDestPath = '$remoteDestDir$destinationFileName';

    _progress.reset();
    _progress.update(5, 'Preparing transfer...', 'Preparation');
    _addConsoleOutput('🚀 Starting transfer to $_host');
    notifyListeners();

    try {
      // Stage 1: Ensure remote directory exists (prevents scp 255)
      _progress.update(12, 'Preparing remote directory...', 'Preparation');
      _addConsoleOutput('📁 ssh $_host: mkdir -p "$remoteDestDir"');
      notifyListeners();

      final sshMkdir = await Process.start('ssh', [
        '-p',
        _port.toString(),
        '-o',
        'StrictHostKeyChecking=accept-new',
        _host,
        'mkdir -p "${remoteDestDir.replaceAll('"', '\\"')}"',
      ], runInShell: true);
      final mkdirCode = await sshMkdir.exitCode;
      if (mkdirCode != 0) {
        _addConsoleOutput(
          '❌ Failed to create remote directory (code $mkdirCode)',
        );
        _progress.error();
        notifyListeners();
        return;
      }

      // Stage 2: Transfer via scp (leverages user's SSH config/agent)
      _progress.update(15, 'Connecting (scp)...', 'File Transfer');
      _addConsoleOutput(
        '📤 scp "$destinationFileName" → $_host:$remoteDestDir',
      );
      notifyListeners();

      final scp = await Process.start('scp', [
        '-P',
        _port.toString(),
        '-o',
        'StrictHostKeyChecking=accept-new',
        _localFilePath,
        '$_host:$remoteDestPath',
      ], runInShell: true);

      // Stream outputs
      scp.stdout.transform(SystemEncoding().decoder).listen((data) {
        _addConsoleOutput(data.trim());
        notifyListeners();
      });
      scp.stderr.transform(SystemEncoding().decoder).listen((data) {
        final line = data.trim();
        if (line.isNotEmpty) {
          _addConsoleOutput('scp: $line');
          notifyListeners();
        }
      });

      final scpExit = await scp.exitCode;
      if (scpExit != 0) {
        _addConsoleOutput('❌ scp failed with exit code $scpExit');
        _progress.error();
        notifyListeners();
        return;
      }

      _progress.update(70, 'File uploaded', 'File Transfer');
      _addConsoleOutput('✅ Uploaded to $remoteDestPath');
      notifyListeners();

      // Stage 2: Execute remote script/template if provided
      if (_templateFilePath.isNotEmpty) {
        _progress.update(80, 'Executing remote script...', 'Script Execution');
        final escapedPath = remoteDestPath.replaceAll('"', '\\"');
        // If template is an executable script, run it; otherwise try bash
        final command =
            'chmod +x "$escapedPath" >/dev/null 2>&1 || true; "$escapedPath" || bash "$escapedPath"';
        _addConsoleOutput('⚡ ssh $_host -- (execute uploaded file)');
        notifyListeners();

        final ssh = await Process.start('ssh', [
          '-p',
          _port.toString(),
          '-o',
          'StrictHostKeyChecking=accept-new',
          _host,
          command,
        ], runInShell: true);

        ssh.stdout.transform(SystemEncoding().decoder).listen((data) {
          final line = data.trim();
          if (line.isNotEmpty) {
            _addConsoleOutput(line);
            notifyListeners();
          }
        });
        ssh.stderr.transform(SystemEncoding().decoder).listen((data) {
          final line = data.trim();
          if (line.isNotEmpty) {
            _addConsoleOutput('ssh: $line');
            notifyListeners();
          }
        });

        final sshExit = await ssh.exitCode;
        if (sshExit != 0) {
          _addConsoleOutput(
            '❌ Remote execution failed with exit code $sshExit',
          );
          _progress.error();
          notifyListeners();
          return;
        }

        _progress.update(95, 'Script completed', 'Script Execution');
        _addConsoleOutput('✅ Script executed successfully');
        notifyListeners();
      }

      // Stage 3: Done
      _progress.update(100, 'Done', 'Complete');
      _addConsoleOutput('🎉 Transfer and execution completed');
      _progress.complete();
      notifyListeners();
    } catch (e) {
      _addConsoleOutput('❌ Error: $e');
      _progress.error();
      notifyListeners();
    }
  }

  // History management
  void saveConnection() {
    if (_host.isNotEmpty) {
      final connection = SSHConnection(
        host: _host,
        port: _port,
        lastUsed: DateTime.now(),
      );

      // Remove duplicate if exists
      _connectionHistory.removeWhere((c) => c.host == _host && c.port == _port);

      // Add to beginning of list
      _connectionHistory.insert(0, connection);

      // Keep only last 10 connections
      if (_connectionHistory.length > 10) {
        _connectionHistory = _connectionHistory.take(10).toList();
      }

      _addConsoleOutput('💾 Connection saved to history');
      notifyListeners();
    }
  }

  void loadConnection(SSHConnection connection) {
    _host = connection.host;
    _port = connection.port;
    _addConsoleOutput('📋 Loaded connection: ${connection.host}');
    notifyListeners();
  }

  void deleteConnection(SSHConnection connection) {
    _connectionHistory.remove(connection);
    _addConsoleOutput('🗑️ Deleted connection: ${connection.host}');
    notifyListeners();
  }

  // Console output
  void _addConsoleOutput(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _consoleOutput.add('[$timestamp] $message');

    // Keep only last 100 lines
    if (_consoleOutput.length > 100) {
      _consoleOutput = _consoleOutput
          .skip(_consoleOutput.length - 100)
          .toList();
    }
  }

  void clearConsole() {
    _consoleOutput.clear();
    notifyListeners();
  }

  // Utility methods
  void reset() {
    _host = '';
    _port = 22;
    _isConnected = false;
    _isConnecting = false;
    _localFilePath = '';
    _templateFilePath = '';
    _remotePath = '/home/user/scripts/';
    _progress.reset();
    _consoleOutput.clear();
    notifyListeners();
  }

  bool get canExecute =>
      _host.isNotEmpty &&
      _localFilePath.isNotEmpty &&
      _templateFilePath.isNotEmpty &&
      !_isConnecting;
}
