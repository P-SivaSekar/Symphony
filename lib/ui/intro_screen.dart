import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'glassmorphic_component.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint("Notification permission error: $e");
    }
  }

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Symphony',
      'description': 'Experience music like never before. Dive into a beautiful, seamless, and dynamic music player tailored for you.',
      'icon': Icons.music_note,
      'color': Colors.blueAccent,
    },
    {
      'title': 'Request Songs Seamlessly',
      'description': "Can't find your favorite track? Request any song directly from the Home screen, and we will add it for you!",
      'icon': Icons.send,
      'color': Colors.purpleAccent,
    },
    {
      'title': 'Create Custom Playlists',
      'description': 'Organize your music your way. Create, edit, and manage your custom playlists effortlessly.',
      'icon': Icons.playlist_add_check,
      'color': Colors.greenAccent,
    },
    {
      'title': 'Enjoy the Experience',
      'description': 'Synchronized lyrics, dynamic themes, seamless transitions, and a personalized player wait for you.',
      'icon': Icons.stars,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.black, const Color(0xFF1A1A2E)]
                    : [Colors.blue.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassContainer(
                      width: 150,
                      height: 150,
                      borderRadius: 75,
                      hasBlur: true,
                      child: Icon(
                        page['icon'],
                        size: 80,
                        color: page['color'],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      page['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      page['description'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom Controls
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    TextButton(
                      onPressed: _currentPage == 0
                          ? null
                          : () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          color: _currentPage == 0
                              ? Colors.transparent
                              : theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Skip Button
                    TextButton(
                      onPressed: () => _finishIntro(context),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Next/Done Button
                    TextButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _finishIntro(context);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Done' : 'Next',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _finishIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro_v1_1', true);
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/'); // Assumes '/' is auth or home
    }
  }
}
