class SSHConnection {
  final String host;
  final int port;
  final String? keyPath;
  final DateTime lastUsed;
  final int useCount;
  final String? nickname;

  SSHConnection({
    required this.host,
    required this.port,
    this.keyPath,
    required this.lastUsed,
    this.useCount = 1,
    this.nickname,
  });

  String get displayName => nickname ?? host;

  String get fullHost => port == 22 ? host : '$host:$port';

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'keyPath': keyPath,
      'lastUsed': lastUsed.toIso8601String(),
      'useCount': useCount,
      'nickname': nickname,
    };
  }

  factory SSHConnection.fromJson(Map<String, dynamic> json) {
    return SSHConnection(
      host: json['host'],
      port: json['port'],
      keyPath: json['keyPath'],
      lastUsed: DateTime.parse(json['lastUsed']),
      useCount: json['useCount'] ?? 1,
      nickname: json['nickname'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSHConnection && other.host == host && other.port == port;
  }

  @override
  int get hashCode => host.hashCode ^ port.hashCode;

  @override
  String toString() {
    return 'SSHConnection(host: $host, port: $port, keyPath: $keyPath)';
  }
}
