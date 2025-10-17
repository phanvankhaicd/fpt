import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PathHistoryService {
  static const String _localFilesKey = 'local_files_history';
  static const String _templateFilesKey = 'template_files_history';
  static const String _remotePathsKey = 'remote_paths_history';
  static const int _maxHistoryLength = 10;

  // Lưu đường dẫn file local
  static Future<void> saveLocalFilePath(String path) async {
    if (path.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getLocalFileHistory();
    
    // Xóa path cũ nếu tồn tại
    history.remove(path);
    // Thêm path mới vào đầu danh sách
    history.insert(0, path);
    
    // Giới hạn số lượng lịch sử
    if (history.length > _maxHistoryLength) {
      history.removeRange(_maxHistoryLength, history.length);
    }
    
    await prefs.setStringList(_localFilesKey, history);
  }

  // Lấy lịch sử file local
  static Future<List<String>> getLocalFileHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_localFilesKey) ?? [];
  }

  // Lưu đường dẫn template file
  static Future<void> saveTemplateFilePath(String path) async {
    if (path.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getTemplateFileHistory();
    
    // Xóa path cũ nếu tồn tại
    history.remove(path);
    // Thêm path mới vào đầu danh sách
    history.insert(0, path);
    
    // Giới hạn số lượng lịch sử
    if (history.length > _maxHistoryLength) {
      history.removeRange(_maxHistoryLength, history.length);
    }
    
    await prefs.setStringList(_templateFilesKey, history);
  }

  // Lấy lịch sử template file
  static Future<List<String>> getTemplateFileHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_templateFilesKey) ?? [];
  }

  // Lưu đường dẫn remote
  static Future<void> saveRemotePath(String path) async {
    if (path.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getRemotePathHistory();
    
    // Xóa path cũ nếu tồn tại
    history.remove(path);
    // Thêm path mới vào đầu danh sách
    history.insert(0, path);
    
    // Giới hạn số lượng lịch sử
    if (history.length > _maxHistoryLength) {
      history.removeRange(_maxHistoryLength, history.length);
    }
    
    await prefs.setStringList(_remotePathsKey, history);
  }

  // Lấy lịch sử remote path
  static Future<List<String>> getRemotePathHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_remotePathsKey) ?? [];
  }

  // Xóa một item khỏi lịch sử local files
  static Future<void> removeLocalFilePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getLocalFileHistory();
    history.remove(path);
    await prefs.setStringList(_localFilesKey, history);
  }

  // Xóa một item khỏi lịch sử template files
  static Future<void> removeTemplateFilePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getTemplateFileHistory();
    history.remove(path);
    await prefs.setStringList(_templateFilesKey, history);
  }

  // Xóa một item khỏi lịch sử remote paths
  static Future<void> removeRemotePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getRemotePathHistory();
    history.remove(path);
    await prefs.setStringList(_remotePathsKey, history);
  }

  // Xóa tất cả lịch sử
  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localFilesKey);
    await prefs.remove(_templateFilesKey);
    await prefs.remove(_remotePathsKey);
  }
}
