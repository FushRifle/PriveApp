import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/ui/pages/auth/auth_design.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please fill all fields', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);
    _showSnackBar('Password changed successfully!');

    Navigator.pop(context);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return AuthPageScaffold(
      title: 'Change password',
      subtitle: 'Use a strong, unique password you do not use elsewhere.',
      icon: Icons.password_rounded,
      child: AuthSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password details',
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current password',
              hint: 'Enter current password',
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New password',
              hint: 'At least 6 characters',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Repeat new password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _changePassword,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: palette.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(
                        'Update password',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final palette = AuthPalette.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: palette.text, fontSize: 14),
      decoration: authInputDecoration(
        context,
        label: label,
        hint: hint,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: palette.muted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
