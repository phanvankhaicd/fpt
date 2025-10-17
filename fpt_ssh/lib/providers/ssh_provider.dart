import 'package:flutter/foundation.dart';
import '../models/ssh_connection.dart';
import '../models/progress_info.dart';

class SSHProvider extends ChangeNotifier {
  // Connection state
  String _host = '';
  int _port = 22;
  String _keyPath = '';
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
  String get keyPath => _keyPath;
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

  void setKeyPath(String keyPath) {
    _keyPath = keyPath;
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
    if (!_isConnected) {
      _addConsoleOutput('❌ Not connected to server');
      return;
    }

    _progress.reset();
    _addConsoleOutput('🚀 Starting file transfer and execution...');
    notifyListeners();

    try {
      // Stage 1: File Transfer (0-80%)
      _progress.update(20, 'Transferring file...', 'File Transfer');
      _addConsoleOutput('📤 Uploading $_localFilePath to $_remotePath');

      // Simulate file transfer
      for (int i = 20; i <= 80; i += 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        _progress.update(i.toDouble(), 'Transferring file...', 'File Transfer');
        notifyListeners();
      }

      _addConsoleOutput('✅ File uploaded successfully');

      // Stage 2: Script Execution (80-95%)
      _progress.update(85, 'Executing script...', 'Script Execution');
      _addConsoleOutput('⚡ Executing remote script...');

      await Future.delayed(const Duration(seconds: 2));
      _progress.update(95, 'Script completed', 'Script Execution');
      _addConsoleOutput('✅ Script executed successfully (exit code: 0)');

      // Stage 3: Cleanup (95-100%)
      _progress.update(100, 'Disconnecting...', 'Cleanup');
      _addConsoleOutput('🔌 Disconnecting from server...');

      await Future.delayed(const Duration(milliseconds: 500));
      _isConnected = false;
      _addConsoleOutput('✅ Disconnected successfully');

      _progress.complete();
      notifyListeners();
    } catch (e) {
      _addConsoleOutput('❌ Error during execution: $e');
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
        keyPath: _keyPath,
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
    _keyPath = connection.keyPath;
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
    _keyPath = '';
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
