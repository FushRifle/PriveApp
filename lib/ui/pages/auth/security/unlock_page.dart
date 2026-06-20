import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/settings/settings_bloc.dart';
import 'package:clique/core/services/security/app_lock_service.dart';

class AppUnlockPage extends StatefulWidget {
  final bool isLoading;
  final int? userId;
  final AppLockSettings? settings;
  final AppLockService appLockService;
  final VoidCallback onUnlocked;

  const AppUnlockPage({
    super.key,
    required this.isLoading,
    required this.userId,
    required this.settings,
    required this.appLockService,
    required this.onUnlocked,
  });

  @override
  State<AppUnlockPage> createState() => _AppUnlockPageState();
}

class _AppUnlockPageState extends State<AppUnlockPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isVerifying = false;
  bool _isBiometricAvailable = false;
  String _pin = '';
  String _savedPin = '';
  String? _errorText;

  bool get _isLocked => widget.settings?.enabled == true;

  @override
  void initState() {
    super.initState();
    _prepareUnlockState();
  }

  @override
  void didUpdateWidget(covariant AppUnlockPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.settings != widget.settings) {
      _prepareUnlockState();
    }
  }

  Future<void> _prepareUnlockState() async {
    if (!_isLocked || widget.isLoading) return;

    final savedPin = widget.settings?.pin ??
        await widget.appLockService.getPin(userId: widget.userId);
    final biometricAvailable = await _canUseBiometrics();
    if (!mounted) return;

    setState(() {
      _savedPin = savedPin ?? '';
      _isBiometricAvailable = biometricAvailable;
      _errorText = null;
    });

    final canUseBiometric =
        widget.settings?.biometricEnabled == true && biometricAvailable;
    if (_savedPin.isEmpty && !canUseBiometric) {
      await _resetUnavailableLock();
    }
  }

  Future<bool> _canUseBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addDigit(String digit) async {
    if (widget.isLoading || _isVerifying || _pin.length >= 4) return;

    setState(() => _pin += digit);

    if (_pin.length == 4) {
      await _verifyPin();
    }
  }

  void _removeDigit() {
    if (widget.isLoading || _isVerifying || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    if (_isVerifying) return;

    if (_savedPin.isEmpty) {
      final refreshedPin =
          await widget.appLockService.getPin(userId: widget.userId);
      if (!mounted) return;
      _savedPin = refreshedPin ?? '';
    }

    if (_savedPin.isEmpty) {
      await _resetUnavailableLock();
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final unlocked = _pin == _savedPin;
    if (!mounted) return;

    if (unlocked) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _isVerifying = false;
      _pin = '';
      _errorText = 'Incorrect PIN';
    });
  }

  Future<void> _verifyBiometric() async {
    final settings = widget.settings;
    if (_isVerifying ||
        settings == null ||
        !settings.biometricEnabled ||
        !_isBiometricAvailable) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      final unlocked = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Clique',
        biometricOnly: true,
      );
      if (!mounted) return;
      if (unlocked) {
        widget.onUnlocked();
        return;
      }
      setState(() => _errorText = 'Authentication failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Authentication unavailable');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resetUnavailableLock() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _pin = '';
      _errorText = null;
    });

    await widget.appLockService.save(
      biometricEnabled: false,
      pinEnabled: false,
      timeoutSeconds: 0,
      pin: null,
      userId: widget.userId,
    );

    if (!mounted) return;
    context.read<SettingsBloc>().add(
          const UpdateSettings(
            appLockEnabled: false,
            appLockBiometricEnabled: false,
            appLockPinEnabled: false,
            appLockTimeoutSeconds: 0,
          ),
        );
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showSpinner = widget.isLoading || _isVerifying;
    final showBiometric =
        widget.settings?.biometricEnabled == true && _isBiometricAvailable;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.primary,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'App locked',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _PinDots(pinLength: _pin.length),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 22,
                    child: showSpinner
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _errorText ?? '',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 22),
                  _UnlockKeypad(
                    enabled: !widget.isLoading && !_isVerifying,
                    showBiometric: showBiometric,
                    onDigit: _addDigit,
                    onBackspace: _removeDigit,
                    onBiometric: _verifyBiometric,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int pinLength;

  const _PinDots({required this.pinLength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: index < pinLength ? AppColors.primary : AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockKeypad extends StatelessWidget {
  final bool enabled;
  final bool showBiometric;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onBiometric;

  const _UnlockKeypad({
    required this.enabled,
    required this.showBiometric,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'bio',
      '0',
      'back',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 16,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == 'bio') {
          return _UnlockKey(
            enabled: enabled && showBiometric,
            onTap: onBiometric,
            child: Icon(
              Icons.fingerprint_rounded,
              color: showBiometric
                  ? AppColors.primary
                  : AppColors.text.withOpacity(0.22),
              size: 34,
            ),
          );
        }

        if (key == 'back') {
          return _UnlockKey(
            enabled: enabled,
            onTap: onBackspace,
            child: Icon(
              Icons.backspace_outlined,
              color: AppColors.text,
              size: 24,
            ),
          );
        }

        return _UnlockKey(
          enabled: enabled,
          onTap: () => onDigit(key),
          child: Text(
            key,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _UnlockKey extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _UnlockKey({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: Opacity(
            opacity: enabled ? 1 : 0.35,
            child: child,
          ),
        ),
      ),
    );
  }
}
