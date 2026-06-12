import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/services/security/app_lock_service.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AppLockService _appLockService = AppLockService.instance;

  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = false;
  String _savedPin = '';
  bool _isVerifying = false;
  bool _isLoading = true;
  String? _error;
  bool _didAutoPrompt = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricAvailable = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _appLockService.load();
      final savedPin = await _appLockService.getPin() ?? '';

      if (!mounted) return;

      setState(() {
        _isBiometricEnabled = settings.biometricEnabled;
        _isPinEnabled = settings.pinEnabled;
        _savedPin = savedPin;
        _isLoading = false;
      });

      if (!_didAutoPrompt) {
        _didAutoPrompt = true;
        await _maybeAutoUnlock();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load app lock settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _maybeAutoUnlock() async {
    if (!_isBiometricEnabled || !_isBiometricAvailable) return;
    if (_isVerifying) return;
    await _enableBiometric();
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
        await _appLockService.save(
          biometricEnabled: true,
          pinEnabled: _isPinEnabled,
          timeoutSeconds: 0,
          pin: _isPinEnabled ? _savedPin : null,
        );
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
        _showSuccessSheet('Biometric lock enabled successfully');
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
    await _persistLockState(
      biometricEnabled: false,
      pinEnabled: _isPinEnabled,
      pin: _isPinEnabled ? _savedPin : null,
    );
    _showSnackBar('Biometric lock disabled');
  }

  Future<void> _enablePin() async {
    if (_savedPin.isEmpty) {
      _showModernPinSetup();
    } else {
      _showModernPinVerify();
    }
  }

  void _showModernPinSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModernPinSetupSheet(),
    ).then((pin) {
      if (pin != null && pin is String && pin.isNotEmpty) {
        _savePin(pin);
      }
    });
  }

  void _showModernPinVerify() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernPinVerifySheet(savedPin: _savedPin),
    ).then((success) {
      if (success == true) {
        _showModernPinSetup();
      }
    });
  }

  Future<void> _disablePin() async {
    await _appLockService.clearPin();
    await _persistLockState(
      biometricEnabled: _isBiometricEnabled,
      pinEnabled: false,
      pin: null,
    );
    _showSnackBar('PIN lock disabled');
  }

  Future<void> _savePin(String pin) async {
    await _persistLockState(
      biometricEnabled: _isBiometricEnabled,
      pinEnabled: true,
      pin: pin,
    );
    if (!mounted) return;
    setState(() {
      _savedPin = pin;
      _isPinEnabled = true;
    });
    _showSuccessSheet('PIN enabled successfully');
  }

  Future<void> _persistLockState({
    required bool biometricEnabled,
    required bool pinEnabled,
    String? pin,
  }) async {
    await _appLockService.save(
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: 0,
      pin: pin,
    );
    if (!mounted) return;
    setState(() {
      _isBiometricEnabled = biometricEnabled;
      _isPinEnabled = pinEnabled;
      if (!pinEnabled) {
        _savedPin = '';
      }
    });
  }

  void _showSuccessSheet(String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (context) => SuccessSheet(message: message),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkCard.withOpacity(0.8)
                  : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDarkMode ? AppColors.primary : AppColors.primary,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 48, bottom: 24),
                child: CircularProgressIndicator(),
              ),

            // Header Illustration
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Secure Your App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred lock method',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? AppColors.greyTextColor
                          : AppColors.lightColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Biometric Section
            if (_isBiometricAvailable)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isVerifying
                        ? null
                        : () {
                            if (!_isBiometricEnabled) {
                              _enableBiometric();
                            }
                          },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.fingerprint,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Biometric Lock',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use fingerprint or face recognition',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkMode
                                            ? AppColors.greyTextColor
                                            : AppColors.lightColor,
                                      ),
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
                                activeTrackColor:
                                    AppColors.primary.withOpacity(0.3),
                              ),
                            ],
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: AppColors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: AppColors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // PIN Section
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PIN Lock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Secure your app with a numeric PIN',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode
                                      ? AppColors.greyTextColor
                                      : AppColors.lightColor,
                                ),
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
                          activeTrackColor: AppColors.primary.withOpacity(0.3),
                        ),
                      ],
                    ),
                    if (_isPinEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: OutlinedButton.icon(
                          onPressed: () => _showModernPinSetup(),
                          icon: Icon(Icons.edit, color: AppColors.primary),
                          label: const Text('Change PIN'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'App lock will require authentication every time you open the app. You can use biometric or PIN, or both.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDarkMode
                            ? AppColors.greyTextColor
                            : AppColors.lightColor,
                      ),
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

// Success Sheet
class SuccessSheet extends StatelessWidget {
  final String message;

  const SuccessSheet({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated success icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.green,
                        AppColors.green.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Success text
          Text(
            'Success!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Done button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern PIN Setup Sheet with Numpad and Progress Steps
class ModernPinSetupSheet extends StatefulWidget {
  const ModernPinSetupSheet({super.key});

  @override
  State<ModernPinSetupSheet> createState() => _ModernPinSetupSheetState();
}

class _ModernPinSetupSheetState extends State<ModernPinSetupSheet> {
  String _pin = '';
  String _confirmPin = '';
  bool _isSettingPin = true;
  bool _isLoading = false;

  void _addDigit(String digit) {
    if (_isSettingPin) {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
        });

        if (_pin.length == 4) {
          _moveToConfirm();
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
        });

        if (_confirmPin.length == 4) {
          _verifyAndClose();
        }
      }
    }
  }

  void _removeLastDigit() {
    setState(() {
      if (_isSettingPin) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _moveToConfirm() {
    setState(() {
      _isSettingPin = false;
    });
  }

  void _verifyAndClose() async {
    if (_pin == _confirmPin) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, _pin);
      }
    } else {
      _showMismatchError();
    }
  }

  void _showMismatchError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PINs do not match. Please try again.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {
      _pin = '';
      _confirmPin = '';
      _isSettingPin = true;
    });
  }

  Widget _buildPinDots(String pin, int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length
                ? AppColors.primary
                : Colors.grey.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 32),

          // Title and progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  _isSettingPin ? 'Create PIN' : 'Confirm PIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSettingPin
                      ? 'Enter a 4-digit PIN to secure your app'
                      : 'Re-enter your PIN to confirm',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStep(1, !_isSettingPin),
                    Container(
                      width: 40,
                      height: 1,
                      color: _isSettingPin
                          ? Colors.grey.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.5),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    _buildStep(2, _isSettingPin),
                  ],
                ),

                const SizedBox(height: 48),

                // PIN dots
                _buildPinDots(_isSettingPin ? _pin : _confirmPin, 4),

                const SizedBox(height: 48),
              ],
            ),
          ),

          // Numpad
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (int i = 1; i <= 9; i++)
                          _buildNumpadButton(
                              i.toString(), () => _addDigit(i.toString())),
                        _buildNumpadButton('delete', _removeLastDigit),
                        _buildNumpadButton('0', () => _addDigit('0')),
                        _buildNumpadButton(
                          'check',
                          () {
                            if ((_isSettingPin && _pin.length == 4) ||
                                (!_isSettingPin && _confirmPin.length == 4)) {
                              if (_isSettingPin) {
                                _moveToConfirm();
                              } else {
                                _verifyAndClose();
                              }
                            }
                          },
                          isEnabled: (_isSettingPin && _pin.length == 4) ||
                              (!_isSettingPin && _confirmPin.length == 4),
                        ),
                      ],
                    ),
                  ),

                  // Cancel button
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step, bool isCompleted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isCompleted ? AppColors.primary : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildNumpadButton(String label, VoidCallback onTap,
      {bool isEnabled = true}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDelete = label == 'delete';
    final isCheck = label == 'check';

    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(60),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? (isDelete || isCheck
                    ? AppColors.primary.withOpacity(0.1)
                    : (isDarkMode ? AppColors.darkCard : Colors.grey[100]))
                : Colors.grey.withOpacity(0.1),
          ),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined,
                    color: isEnabled ? AppColors.primary : Colors.grey,
                    size: 28)
                : isCheck
                    ? Icon(Icons.check_circle,
                        color: isEnabled ? AppColors.primary : Colors.grey,
                        size: 32)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

// Modern PIN Verify Sheet
class ModernPinVerifySheet extends StatefulWidget {
  final String savedPin;

  const ModernPinVerifySheet({
    super.key,
    required this.savedPin,
  });

  @override
  State<ModernPinVerifySheet> createState() => _ModernPinVerifySheetState();
}

class _ModernPinVerifySheetState extends State<ModernPinVerifySheet> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removeLastDigit() {
    setState(() {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_pin == widget.savedPin) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _error = 'Incorrect PIN. Please try again.';
        _pin = '';
      });
    }
  }

  Widget _buildPinDots(String pin, int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length
                ? AppColors.primary
                : Colors.grey.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Text(
                  'Enter PIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 4-digit PIN to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // PIN dots
                _buildPinDots(_pin, 4),

                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 48),
              ],
            ),
          ),

          // Numpad
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (int i = 1; i <= 9; i++)
                          _buildNumpadButton(
                              i.toString(), () => _addDigit(i.toString())),
                        _buildNumpadButton('delete', _removeLastDigit),
                        _buildNumpadButton('0', () => _addDigit('0')),
                        _buildNumpadButton('check', () {}, isEnabled: false),
                      ],
                    ),
                  ),

                  // Cancel button
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String label, VoidCallback onTap,
      {bool isEnabled = true}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDelete = label == 'delete';
    final isCheck = label == 'check';

    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(60),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? (isDelete || isCheck
                    ? AppColors.primary.withOpacity(0.1)
                    : (isDarkMode ? AppColors.darkCard : Colors.grey[100]))
                : Colors.grey.withOpacity(0.1),
          ),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined,
                    color: isEnabled ? AppColors.primary : Colors.grey,
                    size: 28)
                : isCheck
                    ? Icon(Icons.check_circle,
                        color: isEnabled ? AppColors.primary : Colors.grey,
                        size: 32)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
