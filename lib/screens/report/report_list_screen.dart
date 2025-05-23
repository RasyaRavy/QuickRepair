import 'package:flutter/material.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickrepair/utils/status_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  Future<List<ReportModel>>? _reportsFuture;
  String _filterStatus = 'All';
  final List<String> _statusFilters = ['All', 'New', 'Assigned', 'In Progress', 'Completed', 'Cancelled'];
  
  @override
  void initState() {
    super.initState();
    // Ensure user is available before loading reports
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (SupabaseService.currentUser != null) {
        _loadReports();
        // Subscribe to global report changes
        SupabaseService.addReportListener(_handleReportChanges);
      } else {
        // Handle case where user is null, perhaps show a message or redirect
        setState(() {
          _reportsFuture = Future.value([]); // Empty list or an error state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated. Please log in.')),
        );
      }
    });
  }
  
  @override
  void dispose() {
    // Remove the listener when the screen is disposed
    SupabaseService.removeReportListener(_handleReportChanges);
    super.dispose();
  }

  // Handler for report changes
  void _handleReportChanges(dynamic payload) {
    print('Report changes detected in ReportListScreen: ${payload['type'] ?? 'update'}');
    _loadReports();
  }

  Future<void> _loadReports() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      // This case should ideally be handled by the check in initState
      // or by routing guards if the user is not authenticated.
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot load reports: User not found.')),
        );
      }
      setState(() {
        _reportsFuture = Future.value([]);
      });
      return;
    }

    setState(() {
      _reportsFuture = SupabaseService.getOrderedRecords(
        table: 'reports',
        orderBy: 'created_at',
        ascending: false,
        userIdColumn: 'user_id', // Specify the column to filter by
        currentUserId: userId,   // Pass the current user's ID
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
        // Handle errors during data fetching
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading reports: ${error.toString()}')),
          );
        }
        return <ReportModel>[]; // Return empty list on error
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    if (user == null) {
      // Display a message or a login prompt if the user is not logged in
      // This part of the UI might be shown briefly if redirection is slow
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.myReports), // Changed title
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please log in to see your reports.'),
              SizedBox(height: 16),
              // Optionally, add a login button
              // ElevatedButton(onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login), child: Text(AppStrings.login))
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadReports,
        color: Colors.orange,
        child: Column(
          children: [
            // Status Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildStatusFilters(),
            ),
            const Divider(height: 1),
            
            // Reports List
            Expanded(
              child: FutureBuilder<List<ReportModel>>(
                future: _reportsFuture,
                builder: (context, snapshot) {
                  if (_reportsFuture == null) {
                    return const Center(child: Text('Initializing...'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadReports,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.orange.shade300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'You have not submitted any reports yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500, 
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRoutes.createReport);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter reports based on selected status
                  final allReports = snapshot.data!;
                  final filteredReports = _filterStatus == 'All' 
                    ? allReports 
                    : allReports.where((report) => 
                        report.status.toLowerCase() == _filterStatus.toLowerCase() ||
                        (_filterStatus == 'In Progress' && 
                          (report.status.toLowerCase() == 'inprogress' || 
                           report.status.toLowerCase() == 'assigned'))
                      ).toList();
                  
                  if (filteredReports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_filterStatus reports found',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return _buildReportCard(report, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // The FloatingActionButton is now managed by HomeScreen
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _filterStatus == status;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: StatusUtils.buildStatusChip(
              status: status,
              isSelected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterStatus = status;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildReportCard(ReportModel report, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.reportDetail,
            arguments: report,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusUtils.buildStatusBadge(report.status).animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms * index.clamp(0, 10))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                      curve: Curves.easeOutBack
                    ),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms * index.clamp(0, 10)),
                ],
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
                .fadeIn(duration: 400.ms, delay: 200.ms * index.clamp(0, 10))
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
                .fadeIn(duration: 400.ms, delay: 250.ms * index.clamp(0, 10))
                .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
              
              const SizedBox(height: 16),
              
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.orange,
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms * index.clamp(0, 10))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                      curve: Curves.elasticOut
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms * index.clamp(0, 10)),
                  ),
                ],
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.reportDetail,
                          arguments: report,
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 350.ms * index.clamp(0, 10))
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
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 50.ms * index.clamp(0, 10))
      .scale(
        begin: const Offset(0.95, 0.95), 
        end: const Offset(1.0, 1.0),
        duration: 600.ms,
        curve: Curves.easeOutQuint
      );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 