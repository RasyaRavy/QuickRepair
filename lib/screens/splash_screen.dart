import 'package:flutter/material.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Single animation controller for all animations
  late AnimationController _controller;
  
  // All animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textOpacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Simple animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Setup animations
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _textOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    
    // Start the animation
    _controller.forward();
    
    // Navigate after a delay
    Timer(const Duration(milliseconds: 2500), () {
      checkAuthAndNavigate();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void checkAuthAndNavigate() async {
    // Check if onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

    if (!onboardingCompleted) {
      // If onboarding is not completed, navigate to onboarding screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    } else if (SupabaseService.isLoggedIn) {
      // If onboarding is completed and user is logged in, navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else {
      // If onboarding is completed but user is not logged in, navigate to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade400,
                  Colors.deepOrange.shade500,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Logo with clean animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeInAnimation,
                        child: _buildLogo(screenSize),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App name with clean fade animation
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline with clean fade animation
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Text(
                        AppStrings.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Simple loading indicator
                    FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: _buildLoadingIndicator(),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLogo(Size screenSize) {
    const double maxLogoSize = 140.0;
    final logoSize = math.min(screenSize.width * 0.35, maxLogoSize);
  
    return Container(
      width: logoSize,
      height: logoSize,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/wrench.png',
        fit: BoxFit.contain,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
            strokeWidth: 3.0,
          ),
        ),
      ],
    );
  }
} 