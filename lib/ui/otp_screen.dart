import '../utils/constants.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../providers/app_provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  late String _generatedOtp;
  late DateTime _expiryTime;

  @override
  void initState() {
    super.initState();
    _generateAndSendOtp();
  }

  void _generateAndSendOtp() async {
    _generatedOtp = (Random().nextInt(900000) + 100000).toString();
    _expiryTime = DateTime.now().add(const Duration(minutes: 10));

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    String username = AppConstants.adminEmail;
    String password = AppConstants.adminAppPassword;

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Symphony App')
      ..recipients.add(email)
      ..subject = 'Verification Code - Symphony App'
      ..html =
          '''
        <h3>Hello!</h3>
        <p>Your Symphony account verification code is: <strong>$_generatedOtp</strong></p>
        <p>This code is valid for 10 minutes.</p>
      ''';

    try {
      if (!kIsWeb) {
        await send(message, smtpServer);
      } else {
        _generatedOtp = '123456';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(
          kIsWeb ? 'OTP verification bypassed on Web (Use 123456)' : 'OTP sent to $email!'
        )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error 535: Google App Password Revoked. Contact Admin.')),
        );
      }
      print("Email Error: $e");
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.isEmpty) return;

    if (DateTime.now().isAfter(_expiryTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP has expired. Please resend.')),
      );
      return;
    }

    if (enteredOtp == _generatedOtp) {
      Provider.of<AppProvider>(context, listen: false).verifyOtpSession();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  void _cancel() {
    FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    final inputFillColor = isDark 
        ? Colors.white.withOpacity(0.08) 
        : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF030205) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verify Your Identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit OTP code to your registered email. It remains valid for 10 minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 14),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    letterSpacing: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: inputFillColor,
                    hintText: '000000',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _cancel,
                      child: const Text(
                        'Cancel Login',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _generateAndSendOtp,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
