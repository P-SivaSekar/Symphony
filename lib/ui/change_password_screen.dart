import '../utils/constants.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'glassmorphic_component.dart';

enum PasswordChangeStep { confirmCurrent, enterNew, verifyOtp }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  PasswordChangeStep _currentStep = PasswordChangeStep.confirmCurrent;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _generatedOtp;
  DateTime? _expiryTime;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _verifyCurrentPassword() async {
    final password = _currentPasswordController.text.trim();
    if (password.isEmpty) {
      _showError("Please enter your current password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        
        setState(() {
          _currentStep = PasswordChangeStep.enterNew;
        });
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication failed");
    } catch (e) {
      _showError("An error occurred");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitNewPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmNewPasswordController.text.trim();

    if (newPass.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }
    if (newPass != confirmPass) {
      _showError("Passwords do not match");
      return;
    }

    await _generateAndSendOtp();
  }

  Future<void> _generateAndSendOtp() async {
    setState(() => _isLoading = true);

    _generatedOtp = (Random().nextInt(900000) + 100000).toString();
    _expiryTime = DateTime.now().add(const Duration(minutes: 10));

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      _showError("No email found for current user");
      setState(() => _isLoading = false);
      return;
    }

    String username = AppConstants.adminEmail;
    String password = AppConstants.adminAppPassword;

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Symphony App')
      ..recipients.add(email)
      ..subject = 'Password Change Verification - Symphony App'
      ..html = '''
        <h3>Hello!</h3>
        <p>Your verification code to change your password is: <strong>$_generatedOtp</strong></p>
        <p>This code is valid for 10 minutes.</p>
      ''';

    try {
      if (!kIsWeb) {
        await send(message, smtpServer);
      } else {
        // Bypass on web
        _generatedOtp = '123456';
      }
      setState(() {
        _currentStep = PasswordChangeStep.verifyOtp;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                kIsWeb ? 'OTP verification bypassed on Web (Use 123456)' : 'OTP sent to $email!'),
          ),
        );
      }
    } catch (e) {
      _showError('Error 535: Google App Password Revoked. Contact Admin.');
      print("Email Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndChangePassword() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.isEmpty) {
      _showError("Please enter OTP");
      return;
    }

    if (_expiryTime != null && DateTime.now().isAfter(_expiryTime!)) {
      _showError("OTP has expired. Please go back and try again.");
      return;
    }

    if (enteredOtp == _generatedOtp) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(_newPasswordController.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Password changed successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Go back to settings
          }
        }
      } catch (e) {
        _showError("Failed to update password: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _showError("Invalid OTP. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Change Password",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? null : theme.scaffoldBackgroundColor,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.black,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStepView(primaryColor, textColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView(Color primaryColor, Color textColor) {
    switch (_currentStep) {
      case PasswordChangeStep.confirmCurrent:
        return _buildConfirmCurrentPassword(primaryColor, textColor);
      case PasswordChangeStep.enterNew:
        return _buildEnterNewPassword(primaryColor, textColor);
      case PasswordChangeStep.verifyOtp:
        return _buildVerifyOtp(primaryColor, textColor);
    }
  }

  Widget _buildConfirmCurrentPassword(Color primaryColor, Color textColor) {
    return Column(
      key: const ValueKey('confirmCurrent'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 48, color: primaryColor),
        const SizedBox(height: 16),
        Text(
          "Verify Identity",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please enter your current password to continue.",
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _currentPasswordController,
          hint: "Current Password",
          icon: Icons.password,
          obscureText: _obscureCurrent,
          primaryColor: primaryColor,
          textColor: textColor,
          onToggleVisibility: () {
            setState(() => _obscureCurrent = !_obscureCurrent);
          },
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          text: "Next",
          onPressed: _isLoading ? null : _verifyCurrentPassword,
          primaryColor: primaryColor,
          textColor: textColor,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    final email = FirebaseAuth.instance.currentUser?.email;
                    if (email != null) {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Password reset link sent to $email. Please check your inbox."), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      _showError("No email found for current user.");
                    }
                  } catch (e) {
                    _showError("Failed to send reset email: $e");
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
          child: Text(
            "Forgot Password?",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterNewPassword(Color primaryColor, Color textColor) {
    return Column(
      key: const ValueKey('enterNew'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.vpn_key_outlined, size: 48, color: primaryColor),
        const SizedBox(height: 16),
        Text(
          "New Password",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your new password below.",
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _newPasswordController,
          hint: "New Password",
          icon: Icons.lock,
          obscureText: _obscureNew,
          primaryColor: primaryColor,
          textColor: textColor,
          onToggleVisibility: () {
            setState(() => _obscureNew = !_obscureNew);
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmNewPasswordController,
          hint: "Confirm New Password",
          icon: Icons.lock_reset,
          obscureText: _obscureConfirm,
          primaryColor: primaryColor,
          textColor: textColor,
          onToggleVisibility: () {
            setState(() => _obscureConfirm = !_obscureConfirm);
          },
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          text: "Send OTP",
          onPressed: _isLoading ? null : _submitNewPassword,
          primaryColor: primaryColor,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildVerifyOtp(Color primaryColor, Color textColor) {
    return Column(
      key: const ValueKey('verifyOtp'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 48, color: primaryColor),
        const SizedBox(height: 16),
        Text(
          "Email Verification",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We sent a 6-digit OTP to your email.",
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 32,
            letterSpacing: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: textColor.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          text: "Verify & Change",
          onPressed: _isLoading ? null : _verifyOtpAndChangePassword,
          primaryColor: primaryColor,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required Color primaryColor,
    required Color textColor,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: textColor.withOpacity(0.6),
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required Color primaryColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GlassContainer(
        borderRadius: 30,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}


