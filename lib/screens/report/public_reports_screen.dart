import 'package:flutter/material.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quickrepair/utils/status_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PublicReportsScreen extends StatefulWidget {
  const PublicReportsScreen({super.key});

  @override
  State<PublicReportsScreen> createState() => _PublicReportsScreenState();
}

class _PublicReportsScreenState extends State<PublicReportsScreen> {
  Future<List<ReportModel>>? _reportsFuture;
  String _filterStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['All', 'New', 'Assigned', 'In Progress', 'Completed', 'Cancelled'];
  
  // For pull refresh
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Statistics
  int _totalReports = 0;
  int _completedReports = 0;
  int _pendingReports = 0;
  int _inProgressReports = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAllReports();
    
    // Subscribe to global report changes
    SupabaseService.addReportListener(_handleReportChanges);
  }
  
  @override
  void dispose() {
    // Remove the listener when the screen is disposed
    SupabaseService.removeReportListener(_handleReportChanges);
    _searchController.dispose();
    super.dispose();
  }
  
  // Handler for report changes
  void _handleReportChanges(dynamic payload) {
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
        
        // Calculate statistics
        _totalReports = reports.length;
        _completedReports = reports.where((r) => r.status.toLowerCase() == 'completed').length;
        _pendingReports = reports.where((r) => r.status.toLowerCase() == 'new').length;
        _inProgressReports = reports.where((r) => r.status.toLowerCase() == 'in progress' || r.status.toLowerCase() == 'assigned').length;
        
        // Return the reports list
        return reports;
      })
      .catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading reports: ${error.toString()}'),
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

  // Filter reports based on search query and status
  List<ReportModel> _getFilteredReports(List<ReportModel> allReports) {
    // First filter by status
    late List<ReportModel> statusFiltered;
    
    if (_filterStatus == 'All') {
      statusFiltered = allReports;
    } else if (_filterStatus == 'In Progress') {
      // Special handling for "In Progress"
      statusFiltered = allReports.where((report) => 
        report.status.toLowerCase() == 'in progress' || 
        report.status.toLowerCase() == 'inprogress' ||
        report.status.toLowerCase() == 'assigned'
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
             (report.reporterId?.toLowerCase() ?? '').contains(query) ||
             (report.reporterName?.toLowerCase() ?? '').contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Reports'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search reports',
          ),
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () => _showFilterBottomSheet(context),
              tooltip: 'Filter reports',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadAllReports,
        color: Colors.orange,
        child: Column(
          children: [
            // Statistics Card - simplified
            _buildStatisticsCard(),

            // Status Filter Chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildStatusFilters(),
            ),
            
            // Reports List
            Expanded(
              child: FutureBuilder<List<ReportModel>>(
                future: _reportsFuture,
                builder: (context, snapshot) {
                  if (_reportsFuture == null || snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertCircle, size: 48, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          const Text('Error loading reports'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAllReports,
                            child: const Text('Try Again'),
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
                          Icon(LucideIcons.clipboardList, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No reports yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final user = SupabaseService.currentUser;
                              if (user != null) {
                                Navigator.of(context).pushNamed(AppRoutes.createReport);
                              } else {
                                Navigator.of(context).pushNamed(AppRoutes.login);
                              }
                            },
                            child: const Text('Create Report'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter reports based on selected status and search query
                  final filteredReports = _getFilteredReports(snapshot.data!);
                  
                  if (filteredReports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.search, size: 40, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'No results found' 
                                : 'No $_filterStatus reports found',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filterStatus = 'All';
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
      ),
    );
  }

    return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredReports.length,
      itemBuilder: (context, index) {
                      return _buildReportCard(filteredReports[index]);
                    },
                  );
                },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final user = SupabaseService.currentUser;
          if (user != null) {
            Navigator.of(context).pushNamed(AppRoutes.createReport);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to create a report'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pushNamed(AppRoutes.login);
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
  
  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
            _buildStatItem('Total', _totalReports, LucideIcons.clipboardList, Colors.blue),
            _buildStatItem('Pending', _pendingReports, LucideIcons.clock, Colors.orange),
            _buildStatItem('In Progress', _inProgressReports, LucideIcons.hammer, Colors.amber),
            _buildStatItem('Done', _completedReports, LucideIcons.checkCircle, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
          children: [
            Container(
          padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
            color: color.withOpacity(0.1),
                shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
            Text(
          value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
              ),
            ),
          ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Reports'),
        content: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(LucideIcons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
      child: Column(
            mainAxisSize: MainAxisSize.min,
        children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Reports',
            style: TextStyle(
              fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Filter by Status'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusFilters.map((status) {
                  final isSelected = _filterStatus == status;
                  
                  return StatusUtils.buildStatusChip(
                    status: status,
                    isSelected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = status;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'All';
                _searchQuery = '';
                _searchController.clear();
              });
                      Navigator.pop(context);
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _buildReportCard(ReportModel report) {
    // Format date for display
    String formattedDate = timeago.format(report.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.reportDetail,
            arguments: report,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Status and timestamp row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusUtils.buildStatusBadge(report.status),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Report details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Photo (or placeholder)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: report.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: report.photoUrl,
                          width: 60,
                      height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(LucideIcons.image),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(LucideIcons.image),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(LucideIcons.image),
                        ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Report content
                  Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                  
                  // Description
                        const SizedBox(height: 4),
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        
                        // Location
                        const SizedBox(height: 8),
                        Row(
                      children: [
                            Icon(LucideIcons.mapPin, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                    ),
                ],
              ),
            ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 