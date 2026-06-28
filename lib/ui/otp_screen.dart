import '../utils/constants.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../providers/app_provider.dart';
import 'glassmorphic_component.dart';

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

    // Use the provided Gmail App Password
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
          SnackBar(content: Text('Error 535: Google App Password Revoked. Contact Admin.')),
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
      // Verified successfully!
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 48,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We have sent a 6-digit OTP to your email. It is valid for 10 minutes.',
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
                        hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: textColor.withOpacity(0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: GlassContainer(
                        borderRadius: 30,
                        child: ElevatedButton(
                          onPressed: _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                          child: Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _cancel,
                            child: const Text(
                              'Cancel Login',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: _generateAndSendOtp,
                            child: Text(
                              'Resend OTP',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


