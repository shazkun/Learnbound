import 'package:flutter/material.dart';
import 'package:learnbound/database/user_provider.dart';
import 'package:learnbound/screen/auth/login/login_screen.dart';
import 'package:learnbound/util/back_dialog.dart';
import 'package:learnbound/util/design/appbar.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;
  String _message = '';

  Future<void> _sendResetCode() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result =
        await userProvider.sendResetCode(_emailController.text.trim());

    setState(() {
      if (result == null) {
        _message = 'Email not found.';
      } else if (result == 'cooldown') {
        _message = 'Please wait 10 minutes before requesting a new code.';
      } else {
        _codeSent = true;
        _message = 'Code sent to your email. (for test: $result)';
      }
    });
  }

  Future<void> _resetPassword() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.resetPasswordWithCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _newPasswordController.text.trim(),
    );

    setState(() {
      _message = success ? 'Password reset successful!' : 'Invalid code.';
      if (success) {
        _codeSent = false;
        _emailController.clear();
        _codeController.clear();
        _newPasswordController.clear();
      }
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  void dispose() {
    _emailController.clear();
    _newPasswordController.clear();
    _codeController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        titleText: 'Reset Password',
        showBackButton: true,
        onBackPressed: () {
          return CustomExitDialog.show(context,
              usePushReplacement: true, targetPage: LoginScreen());
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: _inputDecoration('Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            if (!_codeSent)
              ElevatedButton(
                onPressed: _sendResetCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Send Code', style: TextStyle(fontSize: 16)),
              ),
            if (_codeSent) ...[
              TextField(
                controller: _codeController,
                decoration: _inputDecoration('Enter Code'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: _inputDecoration('New Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reset Password',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
            const SizedBox(height: 24),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('successful')
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
