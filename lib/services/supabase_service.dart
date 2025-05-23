import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickrepair/models/report_model.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Authentication Methods
  
  // Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword({required String email}) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Get session
  static Session? get currentSession => client.auth.currentSession;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;
  
  // Check and update the status of "New" reports older than one day
  static Future<void> checkAndUpdateNewReportStatus(ReportModel report) async {
    if (report.status.toLowerCase() == 'new') {
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(report.createdAt);
      
      // If the report is older than 24 hours (1 day)
      if (difference.inHours >= 24) {
        await updateRecord(
          table: 'reports',
          id: report.id,
          data: {'status': 'Assigned'},
        );
        
        // Also add an activity entry for this status change
        try {
          await createRecord(
            table: 'report_activities',
            data: {
              'report_id': report.id,
              'user_id': report.userId,
              'activity_type': 'status_changed',
              'previous_value': 'New',
              'new_value': 'Assigned',
            },
          );
        } catch (e) {
          print('Error creating activity log for auto-assignment: $e');
          // Continue even if activity creation fails
        }
      }
    }
  }

  // Database Methods
  
  // Create a record in a table
  static Future<Map<String, dynamic>?> createRecord({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final response = await client.from(table).insert(data).select();
    if (response.isNotEmpty) {
      return response.first;
    }
    return null;
  }

  // Read a record from a table
  static Future<Map<String, dynamic>?> getRecord({
    required String table,
    required String id,
  }) async {
    final response = await client
        .from(table)
        .select()
        .eq('id', id);
    if (response.isNotEmpty) {
      return response.first;
    }
    return null;
  }

  // Read multiple records from a table with filtering options
  static Future<List<Map<String, dynamic>>> getRecords({
    required String table,
    String? column,
    dynamic value,
    String? userIdColumn,
    String? currentUserId,
  }) async {
    var query = client.from(table).select();

    if (column != null && value != null) {
      query = query.eq(column, value);
    }

    if (userIdColumn != null && currentUserId != null) {
      query = query.eq(userIdColumn, currentUserId);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Read records with ordering
  static Future<List<Map<String, dynamic>>> getOrderedRecords({
    required String table,
    required String orderBy,
    bool ascending = false,
    String? userIdColumn,
    String? currentUserId,
  }) async {
    var queryBuilder = client.from(table).select();

    // Add user ID filter if provided
    if (userIdColumn != null && currentUserId != null) {
      queryBuilder = queryBuilder.eq(userIdColumn, currentUserId);
    }
    
    // Then apply ordering
    final response = await queryBuilder.order(orderBy, ascending: ascending);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Read records with pagination
  static Future<List<Map<String, dynamic>>> getPaginatedRecords({
    required String table,
    required int limit,
    int offset = 0,
  }) async {
    final response = await client
        .from(table)
        .select()
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Update a record in a table
  static Future<void> updateRecord({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await client.from(table).update(data).eq('id', id);
  }

  // Delete a record from a table
  static Future<void> deleteRecord({
    required String table,
    required String id,
  }) async {
    try {
      final response = await client
          .from(table)
          .delete()
          .eq('id', id)
          .select();
      
      print('Delete response: $response');
      return;
    } catch (e) {
      print('Error deleting record from $table: $e');
      rethrow;
    }
  }

  // Storage Methods
  
  // Check if bucket exists - Note: Creating buckets should be done via Supabase dashboard
  // This is kept for reference but should not be used in client apps
  static Future<bool> checkBucketExists({required String bucket}) async {
    try {
      final buckets = await client.storage.listBuckets();
      return buckets.any((b) => b.id == bucket);
    } catch (e) {
      print('Error checking if bucket exists: $e');
      // In case of permission errors, assume bucket exists
      // since we expect it to be pre-created in the Supabase dashboard
      return true;
    }
  }
  
  // Upload a file
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List file,
    String? contentType,
  }) async {
    // Note: We now assume the bucket already exists in Supabase
    try {
      // Ensure user is authenticated
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to upload files');
      }
      
      // Add user ID as folder prefix to comply with RLS policy
      final String userPath = '$userId/$path';
      
      await client.storage.from(bucket).uploadBinary(
        userPath,
        file, 
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true, // Overwrite if exists
        ),
      );
      return client.storage.from(bucket).getPublicUrl(userPath);
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Delete a file
  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      // Ensure user is authenticated
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to delete files');
      }
      
      // Check if path already has user ID as prefix
      final String finalPath = path.startsWith('$userId/') ? path : '$userId/$path';
      
      await client.storage.from(bucket).remove([finalPath]);
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  // Get public records with limit
  static Future<List<Map<String, dynamic>>> getPublicRecords({
    required String table,
    required String orderBy,
    bool ascending = false,
    int limit = 20,
  }) async {
    final response = await client
        .from(table)
        .select()
        .order(orderBy, ascending: ascending)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Global RealtimeChannel for reports to be used across all screens
  static RealtimeChannel? _globalReportsChannel;
  static final List<Function> _reportUpdateListeners = [];
  
  // Subscribe to real-time report changes using a simplified approach
  static void subscribeToReportChanges() {
    if (_globalReportsChannel != null) return;
    
    try {
      _globalReportsChannel = client.channel('global_reports_channel');
      
      _globalReportsChannel?.subscribe((status, error) {
        if (error != null) {
          print('Error subscribing to reports: $error');
        } else {
          print('Subscribed to reports channel with status: $status');
          
          // Set up a periodic refresh as a fallback mechanism
          Future.delayed(const Duration(seconds: 5), () {
            _setupPeriodicRefresh();
          });
        }
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
      // Fallback to periodic refresh
      _setupPeriodicRefresh();
    }
  }
  
  static void _setupPeriodicRefresh() {
    // Poll for updates every 30 seconds if we have listeners
    Future.doWhile(() async {
      if (_reportUpdateListeners.isEmpty) return false;
      
      await Future.delayed(const Duration(seconds: 30));
      if (_reportUpdateListeners.isNotEmpty) {
        triggerReportRefresh();
      }
      return _reportUpdateListeners.isNotEmpty;
    });
  }
  
  // Add a listener for report changes
  static void addReportListener(Function callback) {
    if (!_reportUpdateListeners.contains(callback)) {
      _reportUpdateListeners.add(callback);
    }
    
    // Ensure we're subscribed
    subscribeToReportChanges();
  }
  
  // Remove a listener when it's no longer needed
  static void removeReportListener(Function callback) {
    _reportUpdateListeners.remove(callback);
    
    // If there are no more listeners, unsubscribe
    if (_reportUpdateListeners.isEmpty && _globalReportsChannel != null) {
      try {
        _globalReportsChannel!.unsubscribe();
        _globalReportsChannel = null;
        print('Unsubscribed from global report changes');
      } catch (e) {
        print('Error unsubscribing: $e');
      }
    }
  }

  // Manually trigger a refresh for all report listeners
  static void triggerReportRefresh() {
    for (var listener in _reportUpdateListeners) {
      listener({'type': 'refresh'});
    }
  }

  // Fetch recent report activities for the current user
  static Future<List<Map<String, dynamic>>> getRecentReportActivities({
    int limit = 10,
    int? days,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to get recent activities');
    }
    
    try {
      // First, get the activities without the join
      final response = await client
          .from('report_activities')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      // Filter by date on the client side if needed
      final List<Map<String, dynamic>> activities = List<Map<String, dynamic>>.from(response);
      
      // Filter by date if days parameter is provided
      List<Map<String, dynamic>> filteredActivities = activities;
      if (days != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: days));
        filteredActivities = activities.where((item) {
          final DateTime createdAt = DateTime.parse(item['created_at']);
          return createdAt.isAfter(cutoffDate);
        }).toList();
      }
      
      // Now get the report titles in a separate query for each activity
      final List<Map<String, dynamic>> result = [];
      
      for (var activity in filteredActivities) {
        final reportId = activity['report_id'];
        Map<String, dynamic>? reportData;
        
        try {
          final reportResponse = await client
              .from('reports')
              .select('description')
              .eq('id', reportId)
              .limit(1)
              .maybeSingle();
          
          reportData = reportResponse != null 
              ? Map<String, dynamic>.from(reportResponse) 
              : null;
        } catch (e) {
          print('Error fetching report description for $reportId: $e');
          reportData = null;
        }
        
        final activityWithTitle = Map<String, dynamic>.from(activity);
        activityWithTitle['report_title'] = reportData?['description'] ?? 'Untitled Report';
        result.add(activityWithTitle);
      }
      
      return result;
    } catch (e) {
      print('Error fetching recent activities: $e');
      // Return empty list on error
      return [];
    }
  }
  
  // Subscribe to report activity changes
  static RealtimeChannel? _reportActivitiesChannel;
  static final List<Function> _activityUpdateListeners = [];
  
  static void subscribeToActivityChanges() {
    if (_reportActivitiesChannel != null) return;
    
    final userId = currentUser?.id;
    if (userId == null) return;
    
    try {
      // Just use the same polling approach that was working for reports
      _setupPeriodicActivityRefresh();
      print('Set up periodic refresh for activities');
    } catch (e) {
      print('Error setting up activities polling: $e');
    }
  }
  
  static void _setupPeriodicActivityRefresh() {
    // Poll for updates every 15 seconds if we have listeners
    Future.doWhile(() async {
      if (_activityUpdateListeners.isEmpty) return false;
      
      await Future.delayed(const Duration(seconds: 15));
      if (_activityUpdateListeners.isNotEmpty) {
        _triggerActivityRefresh();
      }
      return _activityUpdateListeners.isNotEmpty;
    });
  }
  
  static void _triggerActivityRefresh() {
    for (var listener in _activityUpdateListeners) {
      listener({'type': 'refresh'});
    }
  }
  
  static void addActivityListener(Function callback) {
    if (!_activityUpdateListeners.contains(callback)) {
      _activityUpdateListeners.add(callback);
    }
    
    subscribeToActivityChanges();
  }
  
  static void removeActivityListener(Function callback) {
    _activityUpdateListeners.remove(callback);
  }
  
  // Get the count of reports submitted by the current user
  static Future<int> getCurrentUserReportCount() async {
    final userId = currentUser?.id;
    if (userId == null) {
      return 0;
    }
    
    try {
      final response = await client
          .from('reports')
          .select()
          .eq('user_id', userId);
      
      return response.length;
    } catch (e) {
      print('Error fetching user report count: $e');
      return 0;
    }
  }
  
  // Global function to check and update all "New" reports that are older than 24 hours
  static Future<void> checkAndUpdateAllNewReports() async {
    try {
      // Get all reports with "New" status
      final response = await client
          .from('reports')
          .select()
          .eq('status', 'New');
      
      if (response.isEmpty) return;
      
      final reports = response.map((item) => ReportModel.fromJson(item)).toList();
      final DateTime now = DateTime.now();
      
      // Check each report and update if needed
      for (var report in reports) {
        final Duration difference = now.difference(report.createdAt);
        if (difference.inHours >= 24) {
          // Update the report status
          await updateRecord(
            table: 'reports',
            id: report.id,
            data: {'status': 'Assigned'},
          );
          
          // Add activity log
          await createRecord(
            table: 'report_activities',
            data: {
              'report_id': report.id,
              'user_id': report.userId,
              'activity_type': 'status_changed',
              'previous_value': 'New',
              'new_value': 'Assigned',
            },
          );
          
          // Notify listeners of the change
          triggerReportRefresh();
        }
      }
    } catch (e) {
      print('Error checking for reports to auto-assign: $e');
    }
  }
} 