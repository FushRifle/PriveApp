import 'package:flutter/material.dart';
import 'package:clique/ui/pages/auth/auth_design.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({super.key});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return AuthPageScaffold(
      title: 'Two-factor authentication',
      subtitle: 'Protect your account even if your password is compromised.',
      icon: Icons.verified_user_rounded,
      child: Column(
        children: [
          AuthSectionCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (_isEnabled ? palette.secondary : palette.primary)
                        .withOpacity(palette.isDark ? 0.16 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                    color: _isEnabled ? palette.secondary : palette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnabled ? 'Protection is on' : 'Protection is off',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Require a code from your authenticator when signing in.',
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isEnabled,
                  activeColor: palette.secondary,
                  onChanged: (value) {
                    setState(() => _isEnabled = value);
                    if (value) _showSetupDialog();
                  },
                ),
              ],
            ),
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 12),
            AuthSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recovery codes',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Store these somewhere safe. Each code works once.',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.inputSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        for (int i = 1; i <= 8; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      color: palette.subtle,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  'XXXX-XXXX-XXXX',
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_rounded, size: 17),
                          label: const Text('Download'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: palette.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSetupDialog() {
    final palette = AuthPalette.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Set up two-factor authentication?',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'You will connect an authenticator app and save a set of recovery codes.',
          style: TextStyle(color: palette.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isEnabled = false);
              Navigator.pop(context);
            },
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }
}
