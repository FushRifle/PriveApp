import 'package:clique/core/models/calls.dart';
import 'package:flutter/material.dart';

class CallHistoryItem extends StatelessWidget {
  final CallHistory call;
  final VoidCallback? onTap;

  const CallHistoryItem({
    super.key,
    required this.call,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getCallTypeColor(),
          child: Icon(
            _getCallTypeIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          call.otherUserId.toString(), // Replace with actual user name
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(
              call.direction == 'outgoing' ? Icons.call_made : Icons.call_received,
              size: 14,
              color: _getCallTypeColor(),
            ),
            const SizedBox(width: 4),
            Text(
              call.formattedDuration,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(call.startedAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            call.status.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCallTypeIcon() {
    if (call.status == 'missed' && call.direction == 'incoming') {
      return Icons.call_missed;
    }
    return call.callType == 'video' ? Icons.videocam : Icons.call;
  }

  Color _getCallTypeColor() {
    if (call.status == 'missed' && call.direction == 'incoming') {
      return Colors.red;
    }
    return call.status == 'accepted' ? Colors.green : Colors.orange;
  }

  Color _getStatusColor() {
    switch (call.status) {
      case 'accepted':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'rejected':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(date.weekday)}, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}