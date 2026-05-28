import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout Session'),
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
                const SnackBar(
                  content: Text('Session logged out'),
                  backgroundColor: AppColors.green,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout All Devices'),
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
                const SnackBar(
                  content: Text('Logged out from all other devices'),
                  backgroundColor: AppColors.green,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDarkMode ? AppColors.white : AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Active Sessions',
          style: TextStyle(
            color: isDarkMode ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _sessions.length > 1 ? _logoutAllSessions : null,
            child: Text(
              'Logout All',
              style: TextStyle(
                  color: _sessions.length > 1
                      ? AppColors.red
                      : AppColors.greyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? AppColors.darkBorderColor
                          : AppColors.lightBorderColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          session['icon'],
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  session['device'],
                                  style: AppTheme.blackTextStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (session['current'])
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session['location'],
                              style:
                                  AppTheme.greyTextStyle.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session['browser']} • Last active: ${session['lastActive']}',
                              style:
                                  AppTheme.greyTextStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (!session['current'])
                        IconButton(
                          icon: Icon(Icons.logout,
                              color: AppColors.red, size: 20),
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
