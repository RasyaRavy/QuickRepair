import 'package:flutter/material.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  bool _isAnimating = false;

  // Updated pages with modern illustrations and meaningful content
  late final List<OnboardingPageData> _pages;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pages = [
      OnboardingPageData(
        title: 'Report Damage with Ease',
        description: 'Quickly submit reports with photos and location data to help maintain your school facilities in excellent condition.',
        illustrationWidget: _buildIllustration(
          icon: Icons.report_problem_outlined,
          primaryColor: Colors.blue,
          secondaryColor: Colors.blue.shade200,
        ),
      ),
      OnboardingPageData(
        title: 'Real-Time Tracking',
        description: 'Monitor repair progress in real-time from submission to completion with detailed status updates.',
        illustrationWidget: _buildIllustration(
          icon: Icons.track_changes_outlined,
          primaryColor: Colors.orange,
          secondaryColor: Colors.orange.shade200,
        ),
      ),
      OnboardingPageData(
        title: 'Timely Maintenance',
        description: 'Schedule routine maintenance and get notifications to ensure school facilities are always in optimal condition.',
        illustrationWidget: _buildIllustration(
          icon: Icons.schedule_outlined,
          primaryColor: Colors.green,
          secondaryColor: Colors.green.shade200,
        ),
      ),
    ];
  }

  // Helper method to build an illustration similar to the reference image
  Widget _buildIllustration({
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Book stack
          Positioned(
            bottom: 30,
            child: Container(
              width: 180,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          )
          .animate()
          .slideY(
            begin: 0.5,
            end: 0,
            curve: Curves.easeOutQuad,
            duration: const Duration(milliseconds: 800)
          )
          .fadeIn(duration: const Duration(milliseconds: 600)),
          
          // Open book
          Positioned(
            bottom: 70,
            child: Container(
              width: 200,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 2,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          )
          .animate()
          .slideY(
            begin: 0.5,
            end: 0,
            curve: Curves.easeOutQuad,
            delay: const Duration(milliseconds: 100),
            duration: const Duration(milliseconds: 800)
          )
          .fadeIn(duration: const Duration(milliseconds: 600)),
          
          // Character
          Positioned(
            bottom: 95,
            child: SizedBox(
              height: 120,
              width: 80,
              child: CustomPaint(
                painter: CharacterPainter(primaryColor),
              ),
            ),
          )
          .animate()
          .slideY(
            begin: 0.3,
            end: 0,
            curve: Curves.easeOutQuad,
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 800)
          )
          .fadeIn(duration: const Duration(milliseconds: 600)),
          
          // Icon floating near character
          Positioned(
            right: 80,
            bottom: 140,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: primaryColor,
              ),
            ),
          )
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            curve: Curves.elasticOut,
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 1000)
          )
          .fadeIn(duration: const Duration(milliseconds: 600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin() async {
    // Save a flag that onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  Future<void> _previousPage() async {
    if (_currentPage > 0 && !_isAnimating) {
      _isAnimating = true;
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      _isAnimating = false;
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < _pages.length - 1 && !_isAnimating) {
      _isAnimating = true;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      _isAnimating = false;
      _animationController.reset();
      _animationController.forward();
    } else if (_currentPage == _pages.length - 1) {
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 600))
            .slideX(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: const Duration(milliseconds: 800)
            ),
            
            // PageView for content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemBuilder: (context, index) {
                  final pageData = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        pageData.illustrationWidget,
                        const SizedBox(height: 40),
                        
                        // Page indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pages.length, (dotIndex) {
                              bool isActive = dotIndex == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isActive ? 24 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isActive 
                                    ? colorScheme.primary 
                                    : colorScheme.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                        
                        // Title
                        Text(
                          pageData.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(
                          controller: _animationController, 
                          onPlay: (controller) => controller.forward()
                        )
                        .fadeIn(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 100)
                        )
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          curve: Curves.easeOutQuad,
                          duration: const Duration(milliseconds: 500)
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          pageData.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(
                          controller: _animationController, 
                          onPlay: (controller) => controller.forward()
                        )
                        .fadeIn(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 200)
                        )
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          curve: Curves.easeOutQuad,
                          duration: const Duration(milliseconds: 500)
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _previousPage,
                          child: Text(
                            AppStrings.back,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 300))
                      : const SizedBox(width: 80), // Placeholder for alignment
                  
                  // Next button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? AppStrings.getStarted
                          : AppStrings.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutQuad,
                    duration: const Duration(milliseconds: 800)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final Widget illustrationWidget;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.illustrationWidget,
  });
}

// Custom painter to draw a simple character like in the reference image
class CharacterPainter extends CustomPainter {
  final Color color;

  CharacterPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw body
    final bodyPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..close();
    
    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Draw head
    final headCenter = Offset(size.width * 0.5, size.height * 0.2);
    canvas.drawCircle(headCenter, size.width * 0.18, paint);
    canvas.drawCircle(headCenter, size.width * 0.18, outlinePaint);

    // Draw face
    final eyeSize = size.width * 0.05;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.43, size.height * 0.18),
        width: eyeSize,
        height: eyeSize * 1.2,
      ),
      darkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.18),
        width: eyeSize,
        height: eyeSize * 1.2,
      ),
      darkPaint,
    );

    // Draw smile
    final smilePath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.23)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.28,
        size.width * 0.6, size.height * 0.23,
      );
    canvas.drawPath(smilePath, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Draw arms
    final leftArmPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.1, size.height * 0.3);
    canvas.drawPath(leftArmPath, outlinePaint..strokeWidth = 3);

    final rightArmPath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.4)
      ..lineTo(size.width * 0.9, size.height * 0.35);
    canvas.drawPath(rightArmPath, outlinePaint..strokeWidth = 3);

    // Draw legs
    final leftLegPath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.3, size.height * 0.95);
    canvas.drawPath(leftLegPath, outlinePaint..strokeWidth = 3);

    final rightLegPath = Path()
      ..moveTo(size.width * 0.6, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.95);
    canvas.drawPath(rightLegPath, outlinePaint..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 