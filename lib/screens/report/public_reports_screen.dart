import 'package:flutter/material.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quickrepair/utils/status_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PublicReportsScreen extends StatefulWidget {
  const PublicReportsScreen({super.key});

  @override
  State<PublicReportsScreen> createState() => _PublicReportsScreenState();
}

class _PublicReportsScreenState extends State<PublicReportsScreen> with SingleTickerProviderStateMixin {
  Future<List<ReportModel>>? _reportsFuture;
  String _filterStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['All', 'New', 'Assigned', 'In Progress', 'Completed', 'Cancelled'];
  
  // Remove individual channel
  // RealtimeChannel? _reportsChannel;
  
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _isSearchVisible = false;
  
  // For navigation drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadAllReports();
    
    // Subscribe to global report changes
    SupabaseService.addReportListener(_handleReportChanges);
  }
  
  @override
  void dispose() {
    // Remove the listener when the screen is disposed
    SupabaseService.removeReportListener(_handleReportChanges);
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Handler for report changes
  void _handleReportChanges(dynamic payload) {
    print('Report changes detected in PublicReportsScreen: ${payload['type'] ?? 'update'}');
    _loadAllReports();
  }
  
  Future<void> _loadAllReports() async {
    setState(() {
      _reportsFuture = SupabaseService.getPublicRecords(
        table: 'reports',
        orderBy: 'created_at',
        ascending: false,
        limit: 50, // Get up to 50 reports
      ).then((data) async {
        // Convert the data to a list of ReportModel objects
        final reports = data.map((item) => ReportModel.fromJson(item)).toList();
        
        // Check and update status for reports that are older than one day
        for (var report in reports) {
          await SupabaseService.checkAndUpdateNewReportStatus(report);
        }
        
        // Return the reports list
        return reports;
      })
      .catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Error loading reports: ${error.toString()}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return <ReportModel>[]; // Return empty list on error
      });
    });
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _animationController.forward();
        // Small delay to focus for better UX
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_isSearchVisible && mounted) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
        });
      } else {
        _animationController.reverse();
        // Clear search when closing
        _searchController.clear();
        _searchQuery = '';
        // Remove focus
        FocusScope.of(context).unfocus();
      }
    });
  }

  // Filter reports based on search query and status
  List<ReportModel> _getFilteredReports(List<ReportModel> allReports) {
    // First filter by status
    late List<ReportModel> statusFiltered;
    
    if (_filterStatus == 'All') {
      statusFiltered = allReports;
    } else if (_filterStatus == 'In Progress') {
      // Special handling for "In Progress"
      statusFiltered = allReports.where((report) => 
        report.status.toLowerCase() == 'in progress'
      ).toList();
    } else {
      // For other statuses, do a direct case-insensitive comparison
      statusFiltered = allReports.where((report) =>
        report.status.toLowerCase() == _filterStatus.toLowerCase()
      ).toList();
    }
    
    // Then filter by search query if it exists
    if (_searchQuery.isEmpty) {
      return statusFiltered;
    }
    
    return statusFiltered.where((report) {
      final query = _searchQuery.toLowerCase();
      return report.title.toLowerCase().contains(query) ||
             report.description.toLowerCase().contains(query) ||
             report.location.toLowerCase().contains(query) ||
             (report.reporterId?.toLowerCase() ?? '').contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade600,
                Colors.orange.shade400,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_outlined, 
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Public Reports',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  )
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleSearch,
              tooltip: _isSearchVisible ? 'Close search' : 'Search reports',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _showFilterBottomSheet(context);
              },
              tooltip: 'Filter reports',
            ),
          ),
        ],
        bottom: _isSearchVisible ? PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            shadowColor: Colors.black.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: TextStyle(color: Colors.grey.shade800),
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.orange.shade600),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ) : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  cursorColor: Colors.orange.shade600,
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                ),
              ),
            ),
          ),
        ) : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllReports,
        color: Colors.orange,
        child: Column(
          children: [
            // Status Filter Pills
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
                borderRadius: _isSearchVisible ? BorderRadius.zero : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildStatusFilters(),
            ),
            
            // Reports List
            Expanded(
              child: FutureBuilder<List<ReportModel>>(
                future: _reportsFuture,
                builder: (context, snapshot) {
                  if (_reportsFuture == null) {
                    return _buildLoadingState();
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Filter reports based on selected status and search query
                  final filteredReports = _getFilteredReports(snapshot.data!);
                  
                  if (filteredReports.isEmpty) {
                    return _buildNoMatchingReportsState();
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildReportCard(filteredReports[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _statusFilters.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemBuilder: (context, index) {
        final status = _statusFilters[index];
        final isSelected = _filterStatus == status;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _filterStatus = status;
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isSelected 
                    ? LinearGradient(
                        colors: [
                          StatusUtils.getStatusColor(status),
                          StatusUtils.getStatusColor(status).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                  color: isSelected ? null : StatusUtils.getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: isSelected 
                    ? null 
                    : Border.all(
                        color: StatusUtils.getStatusColor(status).withOpacity(0.5),
                        width: 1,
                      ),
                  boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: StatusUtils.getStatusColor(status).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ] 
                    : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        StatusUtils.getStatusIcon(status),
                        size: 16,
                        color: isSelected ? Colors.white : StatusUtils.getStatusColor(status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? Colors.white : StatusUtils.getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading reports...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAllReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.orange.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade300,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 72,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Be the first to submit a repair report and help improve your campus!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.createReport);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.orange.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchingReportsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.filter_list,
              size: 64,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No $_filterStatus reports found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchQuery.isNotEmpty
                ? 'Try changing your search or filter criteria'
                : 'Try selecting a different status filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _filterStatus = 'All';
                _searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.orange.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final timeAgo = timeago.format(report.createdAt);
    final formattedDate = DateFormat('MMM d, yyyy').format(report.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.reportDetail,
            arguments: report,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report image if available
            if (report.photoUrl != null && report.photoUrl!.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: report.photoUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade200),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => SizedBox(
                        height: 180,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .slide(begin: const Offset(0, 0.2), end: const Offset(0, 0)),
                    
                  // Add a subtle gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  // Position status chip on the image
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusUtils.buildStatusBadge(report.status).animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8), 
                        end: const Offset(1.0, 1.0),
                        duration: 400.ms,
                        curve: Curves.easeOutBack
                      ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: StatusUtils.buildStatusBadge(report.status).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8), 
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOutBack
                  ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date if no image
                  if (report.photoUrl == null || report.photoUrl!.isEmpty)
                    Align(
                      alignment: Alignment.topRight,
                      child: Tooltip(
                        message: formattedDate,
                        child: Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    report.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 16),
                  
                  // Location with enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.orange.shade600,
                        ).animate()
                          .fadeIn(duration: 400.ms, delay: 600.ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            duration: 400.ms,
                            curve: Curves.elasticOut
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            report.location,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).animate()
                            .fadeIn(duration: 400.ms, delay: 600.ms),
                        ),
                      ],
                    ),
                  ),
                  
                  // Reporter info with enhanced styling
                  if (report.reporterName != null && report.reporterName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.blue.shade600,
                            ).animate()
                              .fadeIn(duration: 400.ms, delay: 700.ms)
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.0, 1.0),
                                duration: 400.ms,
                                curve: Curves.elasticOut
                              ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reported by: ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms, delay: 700.ms),
                          Text(
                            report.reporterName!,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms, delay: 750.ms),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons with improved styling
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.reportDetail,
                          arguments: report,
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade500,
                              Colors.orange.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 800.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9), 
                      end: const Offset(1.0, 1.0),
                      duration: 300.ms,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(
        begin: const Offset(0.95, 0.95), 
        end: const Offset(1.0, 1.0),
        duration: 600.ms,
        curve: Curves.easeOutQuint
      );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _statusFilters.map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _filterStatus == status,
                        onSelected: (selected) {
                          setState(() {
                            this.setState(() {
                              _filterStatus = status;
                            });
                          });
                        },
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: _filterStatus == status ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: _filterStatus == status ? 2 : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            this.setState(() {
                              _filterStatus = 'All';
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.orange.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 