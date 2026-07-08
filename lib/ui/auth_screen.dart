import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _showPassword = false;

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }
    if (!_isLogin) {
      final confirmPassword = _confirmPasswordController.text.trim();
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    String? error;
    if (_isLogin) {
      error = await provider.login(email, password);
    } else {
      error = await provider.signup(email, password);
    }

    if (error != null && mounted) {
      if (!_isLogin && error.contains('Mail ID is already registered')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Exists'),
            content: const Text('An account already exists with this email. Please log in instead.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AppProvider>(context).isLoading;
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Logo / Symbol
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // App Title
                Text(
                  'Symphony',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle description
                Text(
                  _isLogin 
                      ? 'Sign in to start streaming high-fidelity audio'
                      : 'Create an account to build your custom playlists',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 36),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFillColor,
                    hintText: 'Email address',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.email_outlined, color: textColor.withOpacity(0.4)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFillColor,
                    hintText: 'Password',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.lock_outline, color: textColor.withOpacity(0.4)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: textColor.withOpacity(0.4),
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

                // Confirm Password (Signup only)
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_showPassword,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      hintText: 'Confirm password',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.lock_reset, color: textColor.withOpacity(0.4)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                ],
                const SizedBox(height: 32),

                // Primary Button (Login/Signup)
                isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Google Sign In Button
                if (!isLoading)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final provider = Provider.of<AppProvider>(context, listen: false);
                      final error = await provider.loginWithGoogle(isLogin: _isLogin);
                      if (error != null && mounted) {
                        if (error.contains('Account already exists')) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Account Exists'),
                              content: const Text('An account already exists with this Google account. Please log in instead.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.login, size: 20, color: textColor),
                    label: Text(
                      _isLogin ? 'Continue with Google' : 'Sign up with Google',
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: textColor.withOpacity(0.15),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Password Reset & Toggle
                if (_isLogin)
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your email address to reset password.')),
                          );
                          return;
                        }
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Password reset link sent to $email.'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send reset link: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? "New to Symphony? " : "Already have an account? ",
                      style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin ? "Sign Up" : "Sign In",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
