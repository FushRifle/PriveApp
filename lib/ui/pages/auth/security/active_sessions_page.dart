import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/ui/pages/auth/auth_design.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage> {
  final bool _isLoading = false;

  final List<Map<String, dynamic>> _sessions = [
    {
      'device': 'iPhone 15 Pro',
      'location': 'Lagos, Nigeria',
      'browser': 'Safari',
      'lastActive': 'Now',
      'current': true,
      'icon': Icons.phone_iphone,
    },
    {
      'device': 'MacBook Pro',
      'location': 'Lagos, Nigeria',
      'browser': 'Chrome',
      'lastActive': '2 hours ago',
      'current': false,
      'icon': Icons.computer,
    },
    {
      'device': 'Samsung Galaxy S23',
      'location': 'Abuja, Nigeria',
      'browser': 'Chrome',
      'lastActive': 'Yesterday',
      'current': false,
      'icon': Icons.phone_android,
    },
  ];

  void _logoutSession(int index) {
    final palette = AuthPalette.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'End this session?',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
            'Are you sure you want to logout from ${_sessions[index]['device']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sessions.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Session logged out'),
                  backgroundColor: AppColors.card,
                ),
              );
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _logoutAllSessions() {
    final palette = AuthPalette.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'End other sessions?',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
        ),
        content: const Text(
            'This will log you out from all devices including this one. You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sessions.removeWhere((s) => !s['current']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Logged out from all other devices'),
                  backgroundColor: AppColors.card,
                ),
              );
            },
            child: const Text('Logout All',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return AuthPageScaffold(
      title: 'Active sessions',
      subtitle: 'Review where your Clique account is currently signed in.',
      icon: Icons.devices_rounded,
      scrollable: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: _sessions.length > 1 ? _logoutAllSessions : null,
            child: Text(
              'End others',
              style: TextStyle(
                color: _sessions.length > 1 ? AppColors.red : palette.subtle,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final isCurrent = session['current'] == true;
                return AuthSectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              (isCurrent ? palette.secondary : palette.primary)
                                  .withOpacity(palette.isDark ? 0.16 : 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          session['icon'],
                          color:
                              isCurrent ? palette.secondary : palette.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    session['device'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.secondary.withOpacity(
                                        palette.isDark ? 0.16 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'This device',
                                      style: TextStyle(
                                        color: palette.secondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session['location']} · ${session['browser']}',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last active ${session['lastActive'].toString().toLowerCase()}',
                              style: TextStyle(
                                color: palette.subtle,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrent)
                        IconButton(
                          tooltip: 'End session',
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.red,
                            size: 19,
                          ),
                          onPressed: () => _logoutSession(index),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
