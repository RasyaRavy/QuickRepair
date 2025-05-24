import 'package:flutter/material.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/screens/report/report_list_screen.dart';
import 'package:quickrepair/screens/profile/profile_screen.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/widgets/welcome_popup.dart';
import 'package:quickrepair/screens/report/public_reports_screen.dart';
import 'package:quickrepair/utils/status_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quickrepair/screens/chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomeDashboardPage(),
    const ReportListScreen(),
    const ChatScreen(),
    const PublicReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Show welcome popup after a short delay to ensure the screen is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcomePopup();
    });
  }

  Future<void> _checkAndShowWelcomePopup() async {
    final shouldShow = await WelcomePopupManager.shouldShowWelcomePopup();
    if (shouldShow && mounted) {
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Get the first part of the email address as a username
        final username = user.email?.split('@').first ?? 'User';
        
        // Show the welcome popup
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return WelcomePopup(
                username: username,
                onClose: () {
                  Navigator.of(context).pop();
                  WelcomePopupManager.markWelcomePopupAsShown();
                },
              );
            },
          );
        }
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        centerTitle: true,
        title: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentIndex == 0 ? LucideIcons.home :
                  _currentIndex == 1 ? LucideIcons.clipboard :
                  _currentIndex == 2 ? LucideIcons.messageCircle :
                  _currentIndex == 3 ? LucideIcons.globe :
                  LucideIcons.user,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  _currentIndex == 0 ? AppStrings.appName :
                  _currentIndex == 1 ? AppStrings.submittedReports :
                  _currentIndex == 2 ? AppStrings.messages :
                  _currentIndex == 3 ? AppStrings.publicReports :
                  AppStrings.profile,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  LucideIcons.bellRing,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                // Handle notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.createReport);
              },
              tooltip: AppStrings.createReport,
              backgroundColor: Colors.orange.shade500,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.orange.shade600,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
            ),
            items: [
              _buildNavBarItem(0, LucideIcons.home, AppStrings.home),
              _buildNavBarItem(1, LucideIcons.clipboard, AppStrings.reports),
              _buildNavBarItem(2, LucideIcons.messageCircle, AppStrings.messages),
              _buildNavBarItem(3, LucideIcons.globe, AppStrings.publicReports),
              _buildNavBarItem(4, LucideIcons.user, AppStrings.profile),
            ],
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavBarItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.all(isSelected ? 12 : 0),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.25),
                      Colors.orange.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.orange.shade600 : Colors.grey.shade500,
          ),
        ).animate(target: isSelected ? 1 : 0)
         .scaleXY(
           duration: 400.ms,
           curve: Curves.easeOutBack,
           begin: 0.8,
           end: 1.0,
         ),
      ),
      label: label,
    );
  }
}

// Home Dashboard Page
class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> with SingleTickerProviderStateMixin {
  Future<List<ReportModel>>? _recentReportsFuture;
  String? _username;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Future<int>? _userReportCountFuture;

  @override
  void initState() {
    super.initState();
    _loadRecentReports();
    _loadUsername();
    _loadUserReportCount();
    
    // Check for reports that need status updates
    _checkAndUpdateReportsStatus();
    
    // Set up a periodic timer to check report statuses
    Future.delayed(const Duration(minutes: 30), () {
      if (mounted) {
        _checkAndUpdateReportsStatus();
      }
    });
    
    // Subscribe to global report changes
    SupabaseService.addReportListener(_handleReportChanges);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }
  
  // Function to check for reports that need status updates
  Future<void> _checkAndUpdateReportsStatus() async {
    try {
      // This will check all "New" reports and update them to "Assigned" if they're older than 24 hours
      await SupabaseService.checkAndUpdateAllNewReports();
    } catch (e) {
      print('Error checking report statuses: $e');
    }
  }
  
  @override
  void dispose() {
    // Remove the listener when the screen is disposed
    SupabaseService.removeReportListener(_handleReportChanges);
    _animationController.dispose();
    super.dispose();
  }

  // Handler for report changes
  void _handleReportChanges(dynamic payload) {
    print('Report changes detected in HomeDashboardPage: ${payload['type'] ?? 'update'}');
    _loadRecentReports();
    _loadUserReportCount(); // Reload user report count when reports change
  }

  void _loadUsername() {
    final user = SupabaseService.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _username = user.email!.split('@').first;
      });
    }
  }

  Future<void> _loadRecentReports() async {
    setState(() {
      // Load the most recent reports from all users
      _recentReportsFuture = SupabaseService.getPublicRecords(
        table: 'reports',
        orderBy: 'created_at',
        ascending: false,
        limit: 5, // Show more recent reports
      ).then((data) {
        final reports = data.map((item) => ReportModel.fromJson(item)).toList();
        return reports;
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading recent reports: ${error.toString()}')),
          );
        }
        return <ReportModel>[];
      });
    });
  }

  // Load the current user's report count
  Future<void> _loadUserReportCount() async {
    setState(() {
      _userReportCountFuture = SupabaseService.getCurrentUserReportCount();
    });
  }

  // Helper method to switch tabs
  void _navigateToReportsTab(BuildContext context) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    homeScreenState?.setState(() {
      homeScreenState._currentIndex = 1; // Index of ReportListScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRecentReports,
      color: Colors.orange.shade500,
      strokeWidth: 2,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + AppBar().preferredSize.height - 100,
            bottom: 24.0,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adjust horizontal padding based on screen width
                final horizontalPadding = constraints.maxWidth > 600 ? 24.0 : 16.0;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card with User Info
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildWelcomeCard(),
                    ),
                    const SizedBox(height: 22),
                    
                    // Quick Actions Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildSectionHeader('Quick Actions', LucideIcons.zap),
                    ),
                    const SizedBox(height: 12),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildQuickActionsGrid(),
                    ),
                    const SizedBox(height: 22),
                    
                    // Recent Reports Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildSectionHeader('Recent Reports', LucideIcons.history),
                    ),
                    const SizedBox(height: 8),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: _buildRecentReportsList(),
                    ),
                    
                    // Bottom padding for floating action button
                    const SizedBox(height: 70),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.3),
                  Colors.orange.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.8),
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (title == 'Recent Reports')
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.orange.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeScreenState?.setState(() {
                      homeScreenState._currentIndex = 3; // Index of PublicReportsScreen
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(
        begin: -0.2,
        end: 0,
        duration: 400.ms, 
        curve: Curves.easeOutQuad,
      );
  }
  
  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 10,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/wrench.png'),
              alignment: Alignment.bottomRight,
              scale: 2.5,
              opacity: 0.15,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      color: Colors.white,
                      size: 30,
                    ),
                  ).animate()
                    .scaleXY(
                      duration: 450.ms,
                      curve: Curves.easeOutBack,
                      begin: 0.8,
                      end: 1.0,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ).animate()
                          .fadeIn(delay: 100.ms)
                          .move(begin: const Offset(0, -10), curve: Curves.easeOutQuad),
                        const SizedBox(height: 4),
                        Text(
                          _username ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ).animate()
                          .fadeIn(delay: 200.ms)
                          .move(begin: const Offset(0, -10), curve: Curves.easeOutQuad),
                      ],
                    ),
                  ),
                  FutureBuilder<int>(
                    future: _userReportCountFuture,
                    builder: (context, snapshot) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.fileText,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              snapshot.hasData 
                                ? '${snapshot.data}' 
                                : snapshot.hasError 
                                  ? '0' 
                                  : '...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 300.ms)
                        .scaleXY(
                          duration: 400.ms, 
                          curve: Curves.easeOutBack,
                          begin: 0.8,
                          end: 1.0,
                        );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.createReport);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
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
                            LucideIcons.plus,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Create New Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate()
                .fadeIn(delay: 400.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 400.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad,
                ),
                
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickInfoCard(
                    title: 'My Reports', 
                    icon: LucideIcons.clipboard,
                    onTap: () => _navigateToReportsTab(context),
                  ),
                  _buildQuickInfoCard(
                    title: 'Public Reports', 
                    icon: LucideIcons.globe,
                    onTap: () {
                      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                      homeScreenState?.setState(() {
                        homeScreenState._currentIndex = 3; // Index of PublicReportsScreen
                      });
                    },
                  ),
                ],
              ).animate()
                .fadeIn(delay: 500.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 500.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad,
                ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scaleXY(
        begin: 0.95,
        end: 1.0,
        duration: 600.ms,
        curve: Curves.easeOutQuad,
      );
  }
  
  Widget _buildQuickInfoCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine if we should use a grid or wrap based on available width
              final bool useGrid = constraints.maxWidth > 400;
              final double itemWidth = useGrid ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
              
              if (useGrid) {
                return Row(
                  children: [
                    _buildQuickActionItem(
                      title: 'My Reports',
                      subtitle: 'Check your activity',
                      icon: LucideIcons.fileText,
                      color: Colors.blue.shade400,
                      onTap: () => _navigateToReportsTab(context),
                      width: itemWidth,
                    ),
                    const SizedBox(width: 16),
                    _buildQuickActionItem(
                      title: 'Public Reports',
                      subtitle: 'Browse public repairs',
                      icon: LucideIcons.globe,
                      color: Colors.green.shade400,
                      onTap: () {
                        final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                        homeScreenState?.setState(() {
                          homeScreenState._currentIndex = 3; // Index of PublicReportsScreen
                        });
                      },
                      width: itemWidth,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildQuickActionItem(
                      title: 'My Reports',
                      subtitle: 'Check your activity',
                      icon: LucideIcons.fileText,
                      color: Colors.blue.shade400,
                      onTap: () => _navigateToReportsTab(context),
                      width: itemWidth,
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionItem(
                      title: 'Public Reports',
                      subtitle: 'Browse public repairs',
                      icon: LucideIcons.globe,
                      color: Colors.green.shade400,
                      onTap: () {
                        final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                        homeScreenState?.setState(() {
                          homeScreenState._currentIndex = 3;
                        });
                      },
                      width: itemWidth,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 500.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 200.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }

  Widget _buildQuickActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Function() onTap,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReportsList() {
    return FutureBuilder<List<ReportModel>>(
      future: _recentReportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingReportsList();
        }
        
        if (snapshot.hasError) {
          return _buildErrorReportsList(snapshot.error.toString());
        }
        
        final reports = snapshot.data ?? [];
        
        if (reports.isEmpty) {
          return _buildEmptyReportsList();
        }
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: reports.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withOpacity(0.1),
                  indent: 22,
                  endIndent: 22,
                ),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportListItem(report, index);
                },
              ),
            ),
          ),
        ).animate()
          .fadeIn(delay: 300.ms, duration: 500.ms)
          .slideY(
            begin: 0.2,
            end: 0,
            delay: 300.ms,
            duration: 500.ms,
            curve: Curves.easeOutQuad,
          );
      },
    );
  }
  
  Widget _buildReportListItem(ReportModel report, int index) {
    final status = report.status;
    final statusColor = StatusUtils.getStatusColor(status);
    
    // Determine the appropriate status icon
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'new':
        statusIcon = LucideIcons.alertCircle;
        break;
      case 'assigned':
        statusIcon = LucideIcons.userCheck;
        break;
      case 'in progress':
        statusIcon = LucideIcons.loader;
        break;
      case 'completed':
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'cancelled':
        statusIcon = LucideIcons.xCircle;
        break;
      default:
        statusIcon = LucideIcons.helpCircle;
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.2),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          statusIcon,
          color: statusColor,
          size: 24,
        ),
      ).animate(delay: (100 * index).ms + 400.ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
      title: Text(
        report.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reported ${_getTimeAgo(report.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: () {
        Navigator.pushNamed(
          context, 
          AppRoutes.reportDetail,
          arguments: report.id
        );
      },
    ).animate(delay: (100 * index).ms + 400.ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  Widget _buildLoadingReportsList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ).animate(delay: 200.ms)
                      .shimmer(duration: 1200.ms, color: Colors.grey.shade100),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ).animate(delay: 400.ms)
                            .shimmer(duration: 1200.ms, color: Colors.grey.shade100),
                          const SizedBox(height: 8),
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ).animate(delay: 600.ms)
                            .shimmer(duration: 1200.ms, color: Colors.grey.shade100),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms);
  }
  
  Widget _buildErrorReportsList(String error) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadRecentReports,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 300.ms, duration: 500.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 300.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }
  
  Widget _buildEmptyReportsList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.clipboardList,
                  color: Colors.orange.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Reports Yet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reports will appear here once they are submitted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.createReport);
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Create First Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 300.ms, duration: 500.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 300.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }
} 