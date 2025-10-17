enum ProgressState {
  idle,
  connecting,
  transferring,
  executing,
  disconnecting,
  completed,
  error,
}

class ProgressInfo {
  double _percentage = 0.0;
  String _status = 'Ready';
  String _currentOperation = '';
  ProgressState _state = ProgressState.idle;
  int _bytesTransferred = 0;
  int _totalBytes = 0;
  double _speed = 0.0; // MB/s
  DateTime? _startTime;

  // Getters
  double get percentage => _percentage;
  String get status => _status;
  String get currentOperation => _currentOperation;
  ProgressState get state => _state;
  int get bytesTransferred => _bytesTransferred;
  int get totalBytes => _totalBytes;
  double get speed => _speed;
  DateTime? get startTime => _startTime;

  // Calculate time remaining
  Duration? get timeRemaining {
    if (_startTime == null || _speed == 0 || _percentage == 0) return null;

    final elapsed = DateTime.now().difference(_startTime!);
    final totalEstimated = Duration(
      milliseconds: (elapsed.inMilliseconds / _percentage * 100).round(),
    );

    return totalEstimated - elapsed;
  }

  // Update progress
  void update(double percentage, String status, String operation) {
    _percentage = percentage.clamp(0.0, 100.0);
    _status = status;
    _currentOperation = operation;

    if (_startTime == null) {
      _startTime = DateTime.now();
    }

    // Update state based on percentage
    if (_percentage < 20) {
      _state = ProgressState.connecting;
    } else if (_percentage < 80) {
      _state = ProgressState.transferring;
    } else if (_percentage < 95) {
      _state = ProgressState.executing;
    } else if (_percentage < 100) {
      _state = ProgressState.disconnecting;
    } else {
      _state = ProgressState.completed;
    }
  }

  // Update file transfer progress
  void updateFileTransfer(int bytesTransferred, int totalBytes) {
    _bytesTransferred = bytesTransferred;
    _totalBytes = totalBytes;

    if (totalBytes > 0) {
      _percentage = (bytesTransferred / totalBytes * 100).clamp(20.0, 80.0);
    }

    // Calculate speed
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!);
      if (elapsed.inSeconds > 0) {
        _speed = (bytesTransferred / 1024 / 1024) / elapsed.inSeconds;
      }
    }
  }

  // Complete progress
  void complete() {
    _percentage = 100.0;
    _status = 'Completed';
    _state = ProgressState.completed;
  }

  // Error state
  void error() {
    _status = 'Error';
    _state = ProgressState.error;
  }

  // Reset progress
  void reset() {
    _percentage = 0.0;
    _status = 'Ready';
    _currentOperation = '';
    _state = ProgressState.idle;
    _bytesTransferred = 0;
    _totalBytes = 0;
    _speed = 0.0;
    _startTime = null;
  }

  // Check if in progress
  bool get isInProgress =>
      _state != ProgressState.idle &&
      _state != ProgressState.completed &&
      _state != ProgressState.error;

  // Get formatted file size
  String get formattedFileSize {
    if (_totalBytes == 0) return '';

    final transferred = _formatBytes(_bytesTransferred);
    final total = _formatBytes(_totalBytes);
    return '$transferred / $total';
  }

  // Get formatted speed
  String get formattedSpeed {
    if (_speed == 0) return '';
    return '${_speed.toStringAsFixed(1)} MB/s';
  }

  // Get formatted time remaining
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining == null) return '';

    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s remaining';
    } else {
      return '${remaining.inSeconds}s remaining';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)}GB';
  }
}
