import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';
import '../models/progress_info.dart';

class ProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SSHProvider>(
      builder: (context, provider, child) {
        final progress = provider.progress;

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
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Progress & Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status indicator
                Row(
                  children: [
                    _buildStatusIndicator(progress.state),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        progress.status,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                LinearProgressIndicator(
                  value: progress.percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progress.state),
                  ),
                  minHeight: 8,
                ),

                const SizedBox(height: 8),

                // Progress details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (progress.currentOperation.isNotEmpty)
                      Text(
                        progress.currentOperation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),

                // File transfer details
                if (progress.state == ProgressState.transferring &&
                    progress.totalBytes > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'File Transfer: ${progress.formattedFileSize}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (progress.speed > 0)
                        Text(
                          progress.formattedSpeed,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),

                  if (progress.timeRemaining != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      progress.formattedTimeRemaining,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                    ),
                  ],
                ],

                // Stage indicators
                if (progress.isInProgress) ...[
                  const SizedBox(height: 16),
                  _buildStageIndicators(progress.state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(ProgressState state) {
    IconData icon;
    Color color;

    switch (state) {
      case ProgressState.idle:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey;
        break;
      case ProgressState.connecting:
        icon = Icons.wifi_find;
        color = Colors.blue;
        break;
      case ProgressState.transferring:
        icon = Icons.upload;
        color = Colors.orange;
        break;
      case ProgressState.executing:
        icon = Icons.play_arrow;
        color = Colors.purple;
        break;
      case ProgressState.disconnecting:
        icon = Icons.wifi_off;
        color = Colors.indigo;
        break;
      case ProgressState.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ProgressState.error:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStageIndicators(ProgressState currentState) {
    final stages = [
      (ProgressState.connecting, 'Connect', Icons.wifi_find),
      (ProgressState.transferring, 'Transfer', Icons.upload),
      (ProgressState.executing, 'Execute', Icons.play_arrow),
      (ProgressState.disconnecting, 'Disconnect', Icons.wifi_off),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stages.map((stage) {
        final (state, label, icon) = stage;
        final isActive = state == currentState;
        final isCompleted = _isStageCompleted(currentState, state);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : isActive
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green
                      : isActive
                      ? Colors.blue
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isStageCompleted(ProgressState currentState, ProgressState stage) {
    final stageOrder = [
      ProgressState.connecting,
      ProgressState.transferring,
      ProgressState.executing,
      ProgressState.disconnecting,
    ];

    final currentIndex = stageOrder.indexOf(currentState);
    final stageIndex = stageOrder.indexOf(stage);

    return currentIndex > stageIndex;
  }

  Color _getProgressColor(ProgressState state) {
    switch (state) {
      case ProgressState.idle:
        return Colors.grey;
      case ProgressState.connecting:
        return Colors.blue;
      case ProgressState.transferring:
        return Colors.orange;
      case ProgressState.executing:
        return Colors.purple;
      case ProgressState.disconnecting:
        return Colors.indigo;
      case ProgressState.completed:
        return Colors.green;
      case ProgressState.error:
        return Colors.red;
    }
  }
}
