import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();

  bool _isBiometricEnabled = false;
  bool _isPinEnabled = false;
  String _savedPin = '';
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricEnabled = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      print('Biometric check error: $e');
    }
  }

  void _loadSettings() {
    // Load from shared preferences or secure storage
    // For now, using demo data
    setState(() {
      _isPinEnabled = false;
      _savedPin = '';
    });
  }

  Future<void> _enableBiometric() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric lock',
        biometricOnly: true,
      );

      if (isAuthenticated) {
        setState(() {
          _isPinEnabled = false;
          _savedPin = '';
        });
        await _saveBiometricEnabled(true);
        _showSnackBar('Biometric lock enabled successfully');
      } else {
        setState(() {
          _error = 'Authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _disableBiometric() async {
    await _saveBiometricEnabled(false);
    setState(() {
      _isBiometricEnabled = false;
    });
    _showSnackBar('Biometric lock disabled');
  }

  Future<void> _enablePin() async {
    if (_savedPin.isEmpty) {
      _showSetPinDialog();
    } else {
      _showVerifyPinDialog();
    }
  }

  void _showSetPinDialog() {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter PIN',
                hintText: '4-6 digits',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                hintText: 'Confirm your PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text;
              final confirm = confirmController.text;

              if (pin.isEmpty || pin.length < 4) {
                _showSnackBar('PIN must be at least 4 digits', isError: true);
                return;
              }

              if (pin != confirm) {
                _showSnackBar('PINs do not match', isError: true);
                return;
              }

              setState(() {
                _savedPin = pin;
                _isPinEnabled = true;
              });

              Navigator.pop(context);
              _showSnackBar('PIN enabled successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showVerifyPinDialog() {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify PIN'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter your PIN',
            hintText: '4-6 digits',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == _savedPin) {
                setState(() {
                  _isPinEnabled = true;
                });
                Navigator.pop(context);
                _showSnackBar('PIN enabled successfully');
              } else {
                _showSnackBar('Incorrect PIN', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _disablePin() async {
    setState(() {
      _isPinEnabled = false;
      _savedPin = '';
    });
    _showSnackBar('PIN lock disabled');
  }

  Future<void> _saveBiometricEnabled(bool enabled) async {
    // Save to shared preferences or secure storage
    // For now, just update state
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Lock',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Biometric Section
            if (_isBiometricEnabled)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? AppColors.darkBorderColor
                        : AppColors.lightBorderColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fingerprint,
                                      color: AppColors.primary, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Biometric Lock',
                                    style: AppTheme.blackTextStyle.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use fingerprint or face recognition',
                                style: AppTheme.greyTextStyle
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isBiometricEnabled,
                          onChanged: _isVerifying
                              ? null
                              : (value) {
                                  if (value) {
                                    _enableBiometric();
                                  } else {
                                    _disableBiometric();
                                  }
                                },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // PIN Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode
                      ? AppColors.darkBorderColor
                      : AppColors.lightBorderColor.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    color: AppColors.primary, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'PIN Lock',
                                  style: AppTheme.blackTextStyle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secure your app with a numeric PIN',
                              style:
                                  AppTheme.greyTextStyle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPinEnabled,
                        onChanged: (value) {
                          if (value) {
                            _enablePin();
                          } else {
                            _disablePin();
                          }
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_isPinEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: () => _showSetPinDialog(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Change PIN'),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'App lock will require authentication every time you open the app. You can use biometric or PIN, or both.',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
