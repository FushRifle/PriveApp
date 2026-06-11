import 'package:flutter/material.dart';

class CallTimer extends StatefulWidget {
  final DateTime? startTime;
  final bool isActive;

  const CallTimer({
    super.key,
    this.startTime,
    this.isActive = true,
  });

  @override
  State<CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<CallTimer> {
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.isActive && widget.startTime != null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CallTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime && widget.startTime != null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _duration = DateTime.now().difference(widget.startTime!);
    setState(() {});
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && widget.isActive) {
        setState(() {
          _duration = DateTime.now().difference(widget.startTime!);
        });
        return true;
      }
      return false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatDuration(_duration),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}