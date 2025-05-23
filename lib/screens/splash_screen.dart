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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Multiple animation controllers for complex animations
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particlesController;
  
  // Main animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  
  // Logo animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  
  // Background animations
  late Animation<double> _gradientPositionAnimation;
  
  // Text reveal animations
  late Animation<double> _textRevealAnimation;
  late Animation<double> _taglineRevealAnimation;
  
  // Particle animations
  final List<ParticleModel> _particles = [];
  final int _particleCount = 12;
  
  @override
  void initState() {
    super.initState();
    
    // Create particles for background effect
    _createParticles();
    
    // Main controller for overall animations
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Pulse animation for continuous effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Rotation controller for logo spin effect
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    );
    
    // Particles controller
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    
    // Setup animation sequences
    _setupAnimations();
    
    // Start the animations
    _mainController.forward();
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _particlesController.repeat();
    
    // Check authentication after a delay
    Timer(const Duration(milliseconds: 3500), () {
      checkAuthAndNavigate();
    });
  }
  
  void _createParticles() {
    final random = math.Random();
    
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        ParticleModel(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 12 + 4,
          velocity: random.nextDouble() * 0.02 + 0.01,
          opacity: random.nextDouble() * 0.6 + 0.2,
          angle: random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }
  
  void _setupAnimations() {
    // Main fade in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Scale animation for content
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    // Slide animation for content
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    // Logo specific animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _logoRotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Background animations
    _gradientPositionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Text reveal animations
    _textRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );
    
    _taglineRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _particlesController.dispose();
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
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController, 
          _pulseController,
          _rotationController,
          _particlesController
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Animated gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.orange.shade800,
                      Colors.deepOrange.shade600,
                      Colors.orange.shade600,
                      Colors.orange.shade400,
                    ],
                    stops: [
                      0.0,
                      0.3 + 0.1 * _gradientPositionAnimation.value,
                      0.6 + 0.1 * _gradientPositionAnimation.value,
                      1.0,
                    ],
                  ),
                ),
              ),
              
              // Background overlay pattern
              CustomPaint(
                painter: SplashPatternPainter(_pulseController.value),
                size: Size.infinite,
              ),
              
              // Animated particles
              CustomPaint(
                painter: ParticlesPainter(
                  particles: _particles,
                  animationValue: _particlesController.value,
                ),
                size: Size.infinite,
              ),
              
              // Circular light effect
              Positioned(
                left: screenSize.width * 0.5,
                top: screenSize.height * 0.3,
                child: Transform.translate(
                  offset: Offset(-150, -150),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.6 * _pulseController.value),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: [0.1, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      
                      // Logo with animations
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Transform.rotate(
                          angle: _logoRotationAnimation.value * math.pi,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: _buildLogo(screenSize),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // App Name with reveal animation
                      FadeTransition(
                        opacity: _textRevealAnimation,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - _textRevealAnimation.value)),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              AppStrings.appName,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2.0,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tagline with staggered reveal
                      FadeTransition(
                        opacity: _taglineRevealAnimation,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _taglineRevealAnimation.value)),
                          child: Text(
                            AppStrings.appTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      
                      const Spacer(flex: 2),
                      
                      // Loading indicator
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: _buildLoadingIndicator(),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildLogo(Size screenSize) {
    const double maxLogoSize = 180.0;
    final logoSize = math.min(screenSize.width * 0.4, maxLogoSize);
  
    return Container(
      width: logoSize,
      height: logoSize,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main logo
          Positioned.fill(
            child: Image.asset(
              'assets/wrench.png',
              fit: BoxFit.contain,
            ),
          ),
          
          // Shine effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.7 * _pulseController.value),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(100),
                  topRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          
          // Rotating glow effect
          RotationTransition(
            turns: _rotationController,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.orange.withOpacity(0.0),
                    Colors.orange.withOpacity(0.5),
                    Colors.orange.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.3, 0.9],
                  startAngle: 0.0,
                  endAngle: math.pi * 2,
                  transform: const GradientRotation(math.pi / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Spinning outer circle
              RotationTransition(
                turns: _rotationController,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.85),
                  ),
                  strokeWidth: 2.5,
                ),
              ),
              
              // Pulsing inner circle
              Transform.scale(
                scale: 0.6 + 0.1 * _pulseController.value,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      'assets/wrench.png',
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Loading...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Custom painter for background pattern
class SplashPatternPainter extends CustomPainter {
  final double animationValue;
  
  SplashPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05 + 0.02 * math.sin(animationValue * math.pi))
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    const spacing = 40.0;
    const diagonal = true;

    // Draw patterns based on animation value
    if (diagonal) {
      // Diagonal lines pattern
      double offset = 10.0 * math.sin(animationValue * math.pi);
      for (double i = -size.width; i < size.width + size.height; i += spacing) {
        canvas.drawLine(
          Offset(i + offset, 0),
          Offset(0, i + offset),
          paint,
        );
      }
      
      // Second set of diagonal lines
      for (double i = -size.width; i < size.width + size.height; i += spacing * 2) {
        canvas.drawLine(
          Offset(size.width, i - size.width + offset),
          Offset(i + offset, size.height),
          paint,
        );
      }
    } else {
      // Grid pattern
      for (double i = 0; i < size.width; i += spacing) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i, size.height),
          paint,
        );
      }
      
      for (double i = 0; i < size.height; i += spacing) {
        canvas.drawLine(
          Offset(0, i),
          Offset(size.width, i),
          paint,
        );
      }
    }
    
    // Draw some decorative circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.07 + 0.03 * math.sin(animationValue * math.pi * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.2),
      50 + 10 * math.sin(animationValue * math.pi),
      circlePaint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.85),
      70 + 5 * math.cos(animationValue * math.pi * 2),
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(SplashPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Particle model for animated background particles
class ParticleModel {
  double x; // Position x (0-1)
  double y; // Position y (0-1)
  double size; // Particle size
  double velocity; // Movement speed
  double opacity; // Transparency
  double angle; // Direction of movement
  
  ParticleModel({
    required this.x,
    required this.y,
    required this.size,
    required this.velocity,
    required this.opacity,
    required this.angle,
  });
  
  void update(double animationValue) {
    // Update position based on velocity and angle
    x += math.cos(angle) * velocity;
    y += math.sin(angle) * velocity;
    
    // Wrap around screen edges
    if (x < 0) x = 1.0;
    if (x > 1) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1) y = 0.0;
    
    // Pulse size with animation
    size += math.sin(animationValue * math.pi * 2) * 0.3;
  }
}

// Custom painter for animated particles
class ParticlesPainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double animationValue;
  
  ParticlesPainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw each particle
    for (var particle in particles) {
      // Update particle position
      particle.update(animationValue);
      
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      // Calculate screen position
      final screenX = particle.x * size.width;
      final screenY = particle.y * size.height;
      
      // Draw the particle
      canvas.drawCircle(
        Offset(screenX, screenY),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 