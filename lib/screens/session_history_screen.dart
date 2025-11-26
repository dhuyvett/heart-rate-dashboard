import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import '../providers/session_history_provider.dart';
import 'session_detail_screen.dart';

/// Session history screen for viewing and managing past workout sessions.
///
/// Displays a list of all completed workout sessions sorted by newest first.
/// Allows users to:
/// - View session details by tapping on a session
/// - Delete individual sessions with swipe-to-delete gesture
/// - Delete all sessions via the app bar menu
///
/// Shows a helpful empty state message when no sessions exist.
class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  ConsumerState<SessionHistoryScreen> createState() =>
      _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  /// Date formatter for displaying session date/time.
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy h:mm a');

  @override
  void initState() {
    super.initState();
    // Reload sessions when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionHistoryProvider.notifier).loadSessions();
    });
  }

  /// Formats duration as HH:MM:SS.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Shows confirmation dialog for deleting a single session.
  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
          'Delete this session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows confirmation dialog for deleting all sessions.
  Future<void> _showDeleteAllConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Sessions'),
        content: const Text(
          'Delete all workout sessions? This will permanently delete all your session history and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(sessionHistoryProvider.notifier).deleteAllSessions();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('All sessions deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting sessions: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Handles dismissing a session (swipe-to-delete).
  Future<bool> _handleDismissSession(WorkoutSession session) async {
    final confirmed = await _showDeleteConfirmation();

    if (confirmed && mounted) {
      try {
        await ref
            .read(sessionHistoryProvider.notifier)
            .deleteSession(session.id!);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Session deleted')));
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting session: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return false;
      }
    }

    return false;
  }

  /// Navigates to session detail screen.
  void _navigateToSessionDetail(WorkoutSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = ref.watch(sessionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'delete_all') {
                _showDeleteAllConfirmation();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 12),
                    Text('Delete All Sessions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: sessions.isEmpty ? _buildEmptyState(theme) : _buildSessionList(),
    );
  }

  /// Builds the empty state view when no sessions exist.
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No workout sessions yet. Start a session to see your history here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of sessions.
  Widget _buildSessionList() {
    final sessions = ref.watch(sessionHistoryProvider);

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionListItem(session);
      },
    );
  }

  /// Builds a single session list item with swipe-to-delete.
  Widget _buildSessionListItem(WorkoutSession session) {
    final theme = Theme.of(context);
    final duration = session.getDuration();
    final dateTimeStr = _dateFormat.format(session.startTime);

    return Dismissible(
      key: Key(session.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => _handleDismissSession(session),
      child: Column(
        children: [
          ListTile(
            title: Text(dateTimeStr),
            subtitle: Text(
              'Duration: ${_formatDuration(duration)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToSessionDetail(session),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
