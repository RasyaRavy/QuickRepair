import 'package:flutter/material.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Activity stats
  int _totalReports = 0;
  int _completedReports = 0;
  int _pendingReports = 0;
  bool _isLoading = true;
  String? _error;
  String? _username;

  @override
  void initState() {
    super.initState();
    
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
    
    // Load activity stats from database
    _loadActivityStats();
    _loadUsername();
    
    // Subscribe to global report changes
    SupabaseService.addReportListener(_handleReportChanges);
  }
  
  void _loadUsername() {
    final user = SupabaseService.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _username = user.email!.split('@').first;
      });
    }
  }

  // Load activity statistics from Supabase
  Future<void> _loadActivityStats() async {
    if (SupabaseService.currentUser == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final userId = SupabaseService.currentUser!.id;
      
      // Fetch all reports for current user
      final reportsData = await SupabaseService.getOrderedRecords(
        table: 'reports',
        orderBy: 'created_at',
        ascending: false,
        userIdColumn: 'user_id',
        currentUserId: userId,
      );
      
      final reports = reportsData.map((data) => ReportModel.fromJson(data)).toList();
      
      // Calculate statistics
      final int total = reports.length;
      final int completed = reports.where((r) => 
        r.status.toLowerCase() == 'completed').length;
      final int pending = total - completed;
      
      if (mounted) {
        setState(() {
          _totalReports = total;
          _completedReports = completed;
          _pendingReports = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // Handler for report changes
  void _handleReportChanges(dynamic payload) {
    print('Report changes detected in ProfileScreen: ${payload['type'] ?? 'update'}');
    _loadActivityStats(); // Reload activity stats when reports change
  }
  
  @override
  void dispose() {
    // Remove the listener when the screen is disposed
    SupabaseService.removeReportListener(_handleReportChanges);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await SupabaseService.signOut();
      if (Navigator.of(context).mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.orange.shade800,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Confirm Log Out',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    children: [
                      // Illustration
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_off_outlined,
                          size: 60,
                          color: Colors.orange.shade300,
                        ),
                      )
                      .animate()
                      .scale(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.0, 1.0),
                      )
                      .fadeIn(),
                      
                      const SizedBox(height: 20),
                      
                      // Message
                      Text(
                        'Are you sure you want to log out?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 150))
                      .slideY(
                        begin: 0.2, 
                        end: 0, 
                        curve: Curves.easeOutQuad,
                        duration: const Duration(milliseconds: 400),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Text(
                        'You will need to enter your credentials again to sign in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 250))
                      .slideY(
                        begin: 0.2, 
                        end: 0, 
                        curve: Curves.easeOutQuad,
                        duration: const Duration(milliseconds: 400),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                
                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(); // Close dialog
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 300))
                        .slideX(begin: -0.2, end: 0),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Logout button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _logout(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Yes, Log Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 400))
                        .slideX(begin: 0.2, end: 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadActivityStats,
        color: Colors.orange,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern Profile Header
              SliverPersistentHeader(
                delegate: _ProfileHeaderDelegate(
                  expandedHeight: 300.0,
                  user: user,
                  username: _username,
                ),
                pinned: true,
              ),
              
              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity Stats Section
                      _buildSectionHeader('Activity Overview', Icons.insert_chart_outlined),
                      const SizedBox(height: 12),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      
                      // Account Settings
                      _buildSectionHeader('Account Settings', Icons.settings),
                      const SizedBox(height: 12),
                      _buildOptionsCard(context),
                      const SizedBox(height: 24),
                      
                      // Support Section
                      _buildSectionHeader('Support & Help', Icons.support_agent),
                      const SizedBox(height: 12),
                      _buildSupportCard(context),
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      _buildLogoutButton(),
                      
                      // App Version
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            'QuickRepair v1.0.0',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.orange.shade700, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(
        begin: -0.2,
        end: 0,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return _buildLoadingStatsCard();
    }
    
    if (_error != null) {
      return _buildErrorStatsCard();
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', _totalReports, Icons.assignment, Colors.blue),
              _buildStatItem('Completed', _completedReports, Icons.check_circle, Colors.green),
              _buildStatItem('Pending', _pendingReports, Icons.pending, Colors.orange),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 500.ms, delay: 200.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 200.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingStatsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorStatsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading activity data. Please try again.',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.orange.shade700, size: 24),
              onPressed: _loadActivityStats,
              tooltip: 'Refresh Stats',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildProfileOption(
              context,
              icon: Icons.edit_outlined,
              title: AppStrings.editProfile,
              subtitle: 'Update your personal information',
              iconColor: Colors.indigo,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
            Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
            _buildProfileOption(
              context,
              icon: Icons.notifications_outlined,
              title: AppStrings.notifications,
              subtitle: 'Configure your notification preferences',
              iconColor: Colors.amber.shade700,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
            Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
            _buildProfileOption(
              context,
              icon: Icons.settings_outlined,
              title: AppStrings.settings,
              subtitle: 'App settings and preferences',
              iconColor: Colors.teal,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 500.ms, delay: 300.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 300.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }
  
  Widget _buildSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildProfileOption(
              context,
              icon: Icons.help_outline,
              title: AppStrings.help,
              subtitle: 'FAQs and usage guides',
              iconColor: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
            Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
            _buildProfileOption(
              context,
              icon: Icons.feedback_outlined,
              title: 'Feedback',
              subtitle: 'Share your thoughts and suggestions',
              iconColor: Colors.cyan,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
            Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
            _buildProfileOption(
              context,
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Learn more about QuickRepair',
              iconColor: Colors.deepOrange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 500.ms, delay: 400.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 400.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.orange).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          color: iconColor ?? Colors.orange,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade500,
          size: 20,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100.withOpacity(0.5),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded, size: 22),
        label: const Text(
          AppStrings.logout,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    ).animate()
      .fadeIn(duration: 500.ms, delay: 500.ms)
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 500.ms,
        duration: 400.ms,
        curve: Curves.easeOutQuad,
      );
  }
}

// Persistent header delegate for the profile header
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final dynamic user;
  final String? username;

  _ProfileHeaderDelegate({
    required this.expandedHeight,
    required this.user,
    this.username,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double shrinkPercentage = shrinkOffset / expandedHeight;
    final double visibleMainHeight = expandedHeight - shrinkOffset;
    
    // Calculate opacity for transition effect
    final opacity = 1.0 - shrinkPercentage * 1.2;
    
    if (user == null) {
      return Container(
        height: expandedHeight,
        color: Colors.orange,
        child: const Center(
          child: Text('Not Logged In', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    
    final userInitial = user.email?[0].toUpperCase() ?? 'U';
    final userEmail = user.email ?? 'N/A';
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.orange.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Opacity(
            opacity: 0.15,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/wrench.png'),
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                  scale: 8.0,
                ),
              ),
            ),
          ),
        ),
    
        // Header content - visible when expanded
        Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Show avatar only when header is expanded enough
              if (visibleMainHeight > expandedHeight / 2)
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 48,
                    child: Text(
                      userInitial,
                      style: TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
              
              // User name display
              Text(
                username ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Color.fromARGB(100, 0, 0, 0),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User email with styling
              Text(
                userEmail,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(
                      color: Color.fromARGB(100, 0, 0, 0),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // User role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'User Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Collapsed Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: kToolbarHeight,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            child: Center(
              child: Opacity(
                // Show title only when collapsed enough
                opacity: shrinkPercentage > 0.6 ? (shrinkPercentage - 0.6) * 2.5 : 0,
                child: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 24; // Fixed height with padding estimate

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
} 