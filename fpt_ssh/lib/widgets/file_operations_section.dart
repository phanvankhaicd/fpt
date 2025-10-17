import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/ssh_provider.dart';

class FileOperationsSection extends StatelessWidget {
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
                      Icons.folder,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'File Operations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Local file selection
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Local File',
                          hintText: 'Select file to upload',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.upload_file),
                          suffixIcon: provider.localFilePath.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      provider.setLocalFilePath(''),
                                )
                              : null,
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: provider.localFilePath.isEmpty
                              ? ''
                              : provider.localFilePath.split('/').last,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _selectLocalFile(provider, context),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Template file selection
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Template File',
                          hintText: 'Select shell script template',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.description),
                          suffixIcon: provider.templateFilePath.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      provider.setTemplateFilePath(''),
                                )
                              : null,
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: provider.templateFilePath.isEmpty
                              ? ''
                              : provider.templateFilePath.split('/').last,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _selectTemplateFile(provider, context),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Remote path
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Remote Path',
                    hintText: '/home/user/scripts/',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.storage),
                  ),
                  onChanged: (value) => provider.setRemotePath(value),
                  controller: TextEditingController(text: provider.remotePath),
                ),

                const SizedBox(height: 12),

                // File info display
                if (provider.localFilePath.isNotEmpty ||
                    provider.templateFilePath.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Selected Files',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (provider.localFilePath.isNotEmpty)
                    _buildFileInfo(
                      context,
                      'Local File',
                      provider.localFilePath,
                      Icons.upload_file,
                      Colors.blue,
                    ),

                  if (provider.templateFilePath.isNotEmpty)
                    _buildFileInfo(
                      context,
                      'Template File',
                      provider.templateFilePath,
                      Icons.description,
                      Colors.green,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileInfo(
    BuildContext context,
    String label,
    String path,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  path,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      print('Starting file picker for local file...');
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      print('File picker result: $result');

      if (result != null && result.files.single.path != null) {
        print('Selected file: ${result.files.single.path}');
        provider.setLocalFilePath(result.files.single.path!);
      } else {
        print('No file selected or path is null');
      }
    } catch (e) {
      print('Error selecting local file: $e');
      // Show error to user
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
      print('Starting file picker for template file...');
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['sh', 'bash', 'txt'],
      );

      print('Template file picker result: $result');

      if (result != null && result.files.single.path != null) {
        print('Selected template file: ${result.files.single.path}');
        provider.setTemplateFilePath(result.files.single.path!);
      } else {
        print('No template file selected or path is null');
      }
    } catch (e) {
      print('Error selecting template file: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting template file: $e')),
      );
    }
  }
}
