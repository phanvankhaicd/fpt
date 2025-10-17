import 'package:flutter/material.dart';
import '../services/path_history_service.dart';

class HistoryDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String value;
  final ValueChanged<String> onChanged;
  final Future<List<String>> Function() getHistory;
  final Future<void> Function(String) saveToHistory;
  final Future<void> Function(String) removeFromHistory;
  final VoidCallback onBrowse;
  final VoidCallback? onClear;

  const HistoryDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.getHistory,
    required this.saveToHistory,
    required this.removeFromHistory,
    required this.onBrowse,
    this.onClear,
  });

  @override
  State<HistoryDropdown> createState() => _HistoryDropdownState();
}

class _HistoryDropdownState extends State<HistoryDropdown> {
  List<String> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await widget.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main input field
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(widget.icon, size: 16),
                  suffixIcon: widget.value.isNotEmpty && widget.onClear != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: widget.onClear,
                          tooltip: 'Clear selection',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  isDense: true,
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: widget.value.isEmpty ? '' : widget.value.split('/').last,
                ),
                onTap: _showHistoryDialog,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: widget.onBrowse,
              icon: const Icon(Icons.folder_open, size: 18),
              tooltip: 'Browse for file',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),

        // History dropdown indicator
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showHistoryDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 12, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${_history.length} recent files',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.blue[700]),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recent ${widget.label}s'),
        content: SizedBox(
          width: double.maxFinite,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? Text(
                      'No recent ${widget.label.toLowerCase()}s found.',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final path = _history[index];
                        final fileName = path.split('/').last;
                        return ListTile(
                          leading: Icon(widget.icon, size: 20),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            path,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                onPressed: () async {
                                  await widget.removeFromHistory(path);
                                  await _loadHistory();
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    _showHistoryDialog();
                                  }
                                },
                                tooltip: 'Remove from history',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, size: 16),
                                onPressed: () async {
                                  widget.onChanged(path);
                                  await widget.saveToHistory(path);
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                tooltip: 'Select this file',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (_history.isNotEmpty)
            TextButton(
              onPressed: () async {
                await PathHistoryService.clearAllHistory();
                await _loadHistory();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }
}
