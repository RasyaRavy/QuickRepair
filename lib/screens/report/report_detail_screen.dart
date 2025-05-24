import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({super.key, required this.report});
  
  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late ReportModel report;
  bool _isDeleted = false;
  
  @override
  void initState() {
    super.initState();
    report = widget.report;
    
    // Subscribe to global report changes
    SupabaseService.addReportListener(_handleReportChanges);
  }
  
  @override
  void dispose() {
    // Remove the listener when the screen is disposed
    SupabaseService.removeReportListener(_handleReportChanges);
    super.dispose();
  }
  
  // Handler for report changes
  void _handleReportChanges(dynamic payload) {
    print('Report changes detected in ReportDetailScreen: ${payload['type'] ?? 'update'}');
    
    // Check if this is a delete event for the current report
    if (payload['type'] == 'DELETE' && 
        payload['old_record'] != null &&
        payload['old_record']['id'] == report.id) {
      setState(() {
        _isDeleted = true;
      });
      
      // Show a message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This report has been deleted'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
      return;
    }
    
    // Check if this is an update event for the current report
    if ((payload['type'] == 'UPDATE' || payload['type'] == 'INSERT') && 
        payload['new_record'] != null &&
        payload['new_record']['id'] == report.id) {
      // Fetch updated report details
      _refreshReport();
    }
  }
  
  // Refresh the report details
  Future<void> _refreshReport() async {
    try {
      final updatedData = await SupabaseService.getRecord(table: 'reports', id: report.id);
      if (updatedData != null && mounted) {
        final updatedReport = ReportModel.fromJson(updatedData);
        
        // Check and update the status if needed
        await SupabaseService.checkAndUpdateNewReportStatus(updatedReport);
        
        // If status was updated, refresh the data again
        if (updatedReport.status.toLowerCase() == 'new') {
          setState(() {
            report = updatedReport;
          });
        } else {
          // Fetch the updated record after status change
          final refreshedData = await SupabaseService.getRecord(table: 'reports', id: report.id);
          if (refreshedData != null && mounted) {
            setState(() {
              report = ReportModel.fromJson(refreshedData);
            });
          }
        }
      }
    } catch (e) {
      print('Error refreshing report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    
    // If the report was deleted, show a placeholder
    if (_isDeleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Report Deleted'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text('This report has been deleted'),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4.0,
        shadowColor: Theme.of(context).colorScheme.shadow,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, size: 20, color: Colors.orange.shade700),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Report Details',
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
          if (SupabaseService.currentUser?.id == report.userId)
            IconButton(
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
                  Icons.more_vert,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                _showActionMenu(context);
              },
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Photo section with gradient overlay
              _buildPhotoSection(context),
              
              // Status card
              _buildStatusCard(context),
              
              // Report details card
              _buildDetailsCard(context, dateFormat),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Stack(
      children: [
        // Photo
        if (report.photoUrl.isNotEmpty)
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Hero(
              tag: report.id,
              child: Image.network(
                report.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => 
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
              ),
            ),
          )
        else
          Container(
            height: 180,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            ),
          ),
          
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Title overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Text(
            report.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (report.status.toLowerCase()) {
      case 'new':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.fiber_new;
        break;
      case 'pending':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'assigned':
        statusColor = Colors.blue.shade600;
        statusIcon = Icons.assignment_ind;
        break;
      case 'inprogress':
      case 'in progress':
        statusColor = Colors.lightBlue.shade600;
        statusIcon = Icons.engineering;
        break;
      case 'completed':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (report.status.toLowerCase() == 'new') _buildNewStatusIcon(statusColor)
              else Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.status,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
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
  
  Widget _buildNewStatusIcon(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.teal.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Text(
          'NEW',
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ).animate()
      .fade(duration: const Duration(milliseconds: 500))
      .scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
      );
  }

  Widget _buildDetailsCard(BuildContext context, DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Report Details', Icons.info_outline),
              const SizedBox(height: 16),
              
              // Description
              _buildDetailItem(
                context, 
                AppStrings.reportDescription, 
                report.description,
                Icons.description_outlined,
                Colors.blue.shade700,
              ),
              const Divider(height: 24),
              
              // Location
              _buildDetailItem(
                context, 
                AppStrings.location, 
                report.location.isNotEmpty ? report.location : 'Lat: ${report.latitude}, Lng: ${report.longitude}',
                Icons.location_on_outlined,
                Colors.red.shade700,
              ),
              const Divider(height: 24),
              
              // Reporter
              if (report.reporterName != null && report.reporterName!.isNotEmpty)
                _buildDetailItem(
                  context, 
                  'Reported By', 
                  report.reporterName!,
                  Icons.person_outline,
                  Colors.deepPurple.shade700,
                ),
              if (report.reporterName != null && report.reporterName!.isNotEmpty)
                const Divider(height: 24),
              
              // Timeline section
              _buildSectionHeader('Timeline', Icons.timeline),
              const SizedBox(height: 16),
              
              // Created At
              _buildTimelineItem(
                context,
                'Reported',
                dateFormat.format(report.createdAt),
                isFirst: true,
                isLast: report.assignedAt == null && report.completedAt == null,
              ),
              
              // Assigned At (if available)
              if (report.assignedAt != null)
                _buildTimelineItem(
                  context,
                  'Assigned',
                  dateFormat.format(report.assignedAt!),
                  isFirst: false,
                  isLast: report.completedAt == null,
                ),
              
              // Completed At (if available)
              if (report.completedAt != null)
                _buildTimelineItem(
                  context,
                  'Completed',
                  dateFormat.format(report.completedAt!),
                  isFirst: false,
                  isLast: true,
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
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, String label, String dateTime, {required bool isFirst, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              // Circle indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isLast ? Colors.orange.shade700 : Colors.orange.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              // Timeline line
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.orange.shade300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLast ? Colors.orange.shade800 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isLast ? 0 : 24),
            ],
          ),
        ),
      ],
    );
  }
  
  // Add this method to show the action menu
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action item: Edit
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('Edit Report'),
              onTap: () {
                Navigator.pop(context);
                _editReport(context);
              },
            ),
            
            // Action item: Delete
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text('Delete Report'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Method to edit the report
  void _editReport(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.createReport,
      arguments: report,
    );
  }

  // Method to show delete confirmation dialog
  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppStrings.deleteReport,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(
                'Delete', 
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteReport(context, report);
    }
  }

  // Method to delete the report
  Future<void> _deleteReport(BuildContext context, ReportModel reportToDelete) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        ),
      );

      // 1. Delete the image from storage if URL exists
      if (reportToDelete.photoUrl.isNotEmpty) {
        try {
          // Parse the URL to extract the path
          final uri = Uri.parse(reportToDelete.photoUrl);
          final pathSegments = uri.pathSegments;
          
          // Extract the path correctly from URL structure
          // Typically: /storage/v1/object/public/[bucket]/[userId]/[filename]
          if (pathSegments.length >= 5 && pathSegments.contains('public')) {
            final bucketIndex = pathSegments.indexOf('public') + 1;
            if (bucketIndex < pathSegments.length) {
              final bucket = pathSegments[bucketIndex];
              
              // The actual path is everything after the bucket name
              final path = pathSegments.sublist(bucketIndex + 1).join('/');
              
              if (path.isNotEmpty) {
                await SupabaseService.deleteFile(bucket: bucket, path: path);
                print('Successfully deleted image from storage: $bucket/$path');
              }
            }
          }
        } catch (storageError) {
          print('Error deleting image from storage: $storageError');
          // Continue with deletion even if image removal fails
        }
      }

      // 2. First delete any related records in dependent tables
      try {
        // Clear chat messages
        await SupabaseService.client
          .from('chat_messages')
          .delete()
          .eq('report_id', reportToDelete.id);
        
        // Clear typing indicators
        await SupabaseService.client
          .from('typing_indicators')
          .delete()
          .eq('report_id', reportToDelete.id);
        
        // Clear messages
        await SupabaseService.client
          .from('messages')
          .delete()
          .eq('report_id', reportToDelete.id);
          
        print('Successfully deleted related records for report ${reportToDelete.id}');
      } catch (relatedError) {
        print('Error deleting related records: $relatedError');
        // Continue with main record deletion
      }

      // 3. Delete the report from the database
      await SupabaseService.deleteRecord(table: 'reports', id: reportToDelete.id);
      print('Successfully deleted report ${reportToDelete.id}');

      // Manually notify all listeners that an update happened
      SupabaseService.triggerReportRefresh();

      // Dismiss the loading dialog
      if (context.mounted) {
        Navigator.pop(context); // Close the loading dialog
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report deleted successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Navigate back to the report list and trigger a refresh
        Navigator.of(context).pop(true); // Pass true to indicate deletion
      }
    } catch (e) {
      // Dismiss the loading dialog
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      
      // Show error message with detailed information
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting report: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _deleteReport(context, reportToDelete),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }
} 