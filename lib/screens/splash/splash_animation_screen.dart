import 'package:flutter/material.dart';
import '../../main.dart'; // To navigate to AuthWrapper
import '../../theme/app_theme.dart';

class SplashAnimationScreen extends StatefulWidget {
  const SplashAnimationScreen({Key? key}) : super(key: key);

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );

    // Moves the service technician from left (-1.5) to right (0.15)
    _moveAnimation = Tween<double>(begin: -1.5, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Pulse effect on the destination house
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.95, curve: Curves.elasticOut),
      ),
    );

    // General fade out at the very end
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppTheme.lightBlueBackground.withOpacity(0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Top Slogan
                Align(
                  alignment: const Alignment(0, -0.6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ME Service Manager',
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'MEET ELECTRONICS',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Animation Track (Center of Screen)
                Center(
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Road line
                        Positioned(
                          bottom: 50,
                          left: 40,
                          right: 40,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Destination: House
                        Positioned(
                          bottom: 35,
                          right: screenWidth * 0.12,
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.green[100]!, width: 1),
                                  ),
                                  child: Icon(
                                    Icons.home_work_rounded,
                                    color: Colors.green[600],
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Customer',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Moving Actor: Technician
                        AnimatedBuilder(
                          animation: _moveAnimation,
                          builder: (context, child) {
                            return Positioned(
                              bottom: 35,
                              left: (screenWidth / 2) + (_moveAnimation.value * screenWidth),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightBlueBackground,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue.withOpacity(0.1),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.engineering_rounded, // Technician icon
                                      color: AppTheme.primaryBlue,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Technician',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading Text / Slogan
                Align(
                  alignment: const Alignment(0, 0.7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Technician en route...',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                          fontStyle: FontStyle.italic,
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
    );
  }
}
