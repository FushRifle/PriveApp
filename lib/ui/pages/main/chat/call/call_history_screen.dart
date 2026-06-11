import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/ui/widgets/call/call_history_item.dart';
import 'package:flutter/material.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallService _callService = CallService();
  final List<CallHistory> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final hasHistory = _history.isNotEmpty;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _callService.getCallHistory();
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(history);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = !hasHistory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(
        child: Text('No call history yet'),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              return CallHistoryItem(call: _history[index]);
            },
          ),
        ),
        if (_isLoading && _history.isNotEmpty)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_error != null && _history.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Material(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'History could not refresh right now',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
