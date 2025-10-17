import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/ssh_provider.dart';
import '../theme/app_theme.dart';

class FileOperationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 3,
          shadowColor: AppTheme.cardShadow,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, AppTheme.lightGray.withOpacity(0.3)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern header with gradient
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.successGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.folder,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'File Operations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Compact status indicator
                        if (provider.localFilePath.isNotEmpty &&
                            provider.templateFilePath.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Ready',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Compact file selection
                  _buildCompactFileSelector(
                    context,
                    provider,
                    'Local File',
                    provider.localFilePath,
                    Icons.upload_file,
                    AppTheme.primaryBlue,
                    () => _selectLocalFile(provider, context),
                    () => provider.setLocalFilePath(''),
                  ),

                  const SizedBox(height: 12),

                  _buildCompactFileSelector(
                    context,
                    provider,
                    'Template File',
                    provider.templateFilePath,
                    Icons.description,
                    AppTheme.secondaryGreen,
                    () => _selectTemplateFile(provider, context),
                    () => provider.setTemplateFilePath(''),
                  ),

                  const SizedBox(height: 12),

                  // Remote path - compact
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Remote Path',
                      hintText: '/home/user/scripts/',
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.storage,
                          size: 18,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.accentOrange,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => provider.setRemotePath(value),
                    controller: TextEditingController(
                      text: provider.remotePath,
                    ),
                  ),

                  // Compact file info display
                  if (provider.localFilePath.isNotEmpty ||
                      provider.templateFilePath.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _buildCompactFileInfo(provider.localFilePath, 'Local'),
                    if (provider.templateFilePath.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildCompactFileInfo(
                        provider.templateFilePath,
                        'Template',
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactFileSelector(
    BuildContext context,
    SSHProvider provider,
    String label,
    String filePath,
    IconData icon,
    Color color,
    VoidCallback onSelect,
    VoidCallback onClear,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          // File info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    filePath.isEmpty
                        ? 'No file selected'
                        : filePath.split('/').last,
                    style: TextStyle(
                      fontSize: 14,
                      color: filePath.isEmpty
                          ? AppTheme.textLight
                          : AppTheme.textPrimary,
                      fontWeight: filePath.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filePath.isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Clear selection',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    backgroundColor: AppTheme.errorRed.withOpacity(0.1),
                  ),
                ),
              IconButton(
                onPressed: onSelect,
                icon: const Icon(Icons.folder_open, size: 18),
                tooltip: 'Browse for file',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                style: IconButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: color.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFileInfo(String path, String type) {
    if (path.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            type == 'Local' ? Icons.upload_file : Icons.description,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '$type: ${path.split('/').last}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocalFile(
    SSHProvider provider,
    BuildContext context,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        provider.setLocalFilePath(result.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  Future<void> _selectTemplateFile(
    SSHProvider provider,
    BuildContext context,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sh', 'bash', 'py', 'js', 'ts'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        provider.setTemplateFilePath(result.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting template: $e')));
    }
  }
}
