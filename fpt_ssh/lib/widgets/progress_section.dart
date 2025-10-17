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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact header
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Progress & Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Progress status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getProgressColor(
                          progress.state,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getProgressColor(progress.state),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getProgressIcon(progress.state),
                            size: 12,
                            color: _getProgressColor(progress.state),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${progress.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getProgressColor(progress.state),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status indicator - compact
                Row(
                  children: [
                    _buildCompactStatusIndicator(progress.state),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.status,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress bar - compact
                LinearProgressIndicator(
                  value: progress.percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progress.state),
                  ),
                  minHeight: 6,
                ),

                const SizedBox(height: 6),

                // Progress details - compact
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    if (progress.currentOperation.isNotEmpty)
                      Expanded(
                        child: Text(
                          progress.currentOperation,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),

                // File transfer details - compact
                if (progress.state == ProgressState.transferring &&
                    progress.totalBytes > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transfer: ${progress.formattedFileSize}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                      if (progress.speed > 0)
                        Text(
                          progress.formattedSpeed,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                    ],
                  ),

                  if (progress.timeRemaining != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      progress.formattedTimeRemaining,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],

                // Stage indicators - compact (vertical layout for narrow space)
                if (progress.isInProgress) ...[
                  const SizedBox(height: 8),
                  _buildVerticalStageIndicators(progress.state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatusIndicator(ProgressState state) {
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildVerticalStageIndicators(ProgressState currentState) {
    final stages = [
      (ProgressState.connecting, 'Connect', Icons.wifi_find),
      (ProgressState.transferring, 'Transfer', Icons.upload),
      (ProgressState.executing, 'Execute', Icons.play_arrow),
      (ProgressState.disconnecting, 'Disconnect', Icons.wifi_off),
    ];

    return Column(
      children: stages.map((stage) {
        final (state, label, icon) = stage;
        final isActive = state == currentState;
        final isCompleted = _isStageCompleted(currentState, state);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : isActive
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : isActive
                        ? Colors.blue
                        : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isCompleted
                      ? Colors.green
                      : isActive
                      ? Colors.blue
                      : Colors.grey,
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
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
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactStageIndicators(ProgressState currentState) {
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : isActive
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green
                      : isActive
                      ? Colors.blue
                      : Colors.grey,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey,
                size: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
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

  IconData _getProgressIcon(ProgressState state) {
    switch (state) {
      case ProgressState.idle:
        return Icons.radio_button_unchecked;
      case ProgressState.connecting:
        return Icons.wifi_find;
      case ProgressState.transferring:
        return Icons.upload;
      case ProgressState.executing:
        return Icons.play_arrow;
      case ProgressState.disconnecting:
        return Icons.wifi_off;
      case ProgressState.completed:
        return Icons.check_circle;
      case ProgressState.error:
        return Icons.error;
    }
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
