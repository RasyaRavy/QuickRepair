import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickrepair/utils/status_utils.dart';

class ReportActivityModel {
  final String id;
  final String reportId;
  final String userId;
  final String activityType;
  final String? previousValue;
  final String? newValue;
  final DateTime createdAt;
  final String reportTitle;
  
  ReportActivityModel({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.activityType,
    this.previousValue,
    this.newValue,
    required this.createdAt,
    required this.reportTitle,
  });
  
  factory ReportActivityModel.fromJson(Map<String, dynamic> json) {
    return ReportActivityModel(
      id: json['id'],
      reportId: json['report_id'],
      userId: json['user_id'],
      activityType: json['activity_type'],
      previousValue: json['previous_value'],
      newValue: json['new_value'],
      createdAt: DateTime.parse(json['created_at']),
      reportTitle: json['report_title'] ?? 'Untitled Report',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'user_id': userId,
      'activity_type': activityType,
      'previous_value': previousValue,
      'new_value': newValue,
      'created_at': createdAt.toIso8601String(),
      'report_title': reportTitle,
    };
  }
  
  // Get the appropriate description for the activity
  String getDescription() {
    final String reportRef = '#${reportId.substring(0, 4)}';
    
    switch (activityType) {
      case 'created':
        return 'Report $reportRef was created';
      case 'status_changed':
        return 'Report $reportRef changed from ${previousValue ?? 'Unknown'} to ${newValue ?? 'Unknown'}';
      case 'assigned':
        return 'Report $reportRef was assigned to ${newValue ?? 'someone'}';
      case 'completed':
        return 'Report $reportRef was completed';
      case 'cancelled':
        return 'Report $reportRef was cancelled';
      default:
        return 'Activity on report $reportRef';
    }
  }
  
  // Get a formatted time string (e.g., "2 hours ago")
  String getFormattedTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(createdAt);
    }
  }
  
  // Get the appropriate color for this activity type
  Color getActivityColor() {
    switch (activityType) {
      case 'created':
        return Colors.blue;
      case 'status_changed':
        if (newValue == 'In Progress') {
          return Colors.orange;
        } else if (newValue == 'Completed') {
          return Colors.green;
        } else if (newValue == 'Cancelled') {
          return Colors.red;
        } else if (newValue == 'Assigned') {
          return Colors.amber;
        } else {
          return Colors.purple;
        }
      case 'assigned':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // Get the status text to display in the activity item
  String getStatusText() {
    if (activityType == 'status_changed' && newValue != null) {
      return newValue!;
    } else if (activityType == 'created') {
      return 'New';
    } else if (activityType == 'assigned') {
      return 'Assigned';
    } else if (activityType == 'completed') {
      return 'Completed';
    } else if (activityType == 'cancelled') {
      return 'Cancelled';
    } else {
      return activityType;
    }
  }
  
  // Get the appropriate icon for this activity type
  IconData getActivityIcon() {
    if (activityType == 'status_changed' && newValue != null) {
      return StatusUtils.getStatusIcon(newValue!);
    } else {
      switch (activityType) {
        case 'created':
          return StatusUtils.getStatusIcon('New');
        case 'assigned':
          return StatusUtils.getStatusIcon('Assigned');
        case 'completed':
          return StatusUtils.getStatusIcon('Completed');
        case 'cancelled':
          return StatusUtils.getStatusIcon('Cancelled');
        default:
          return StatusUtils.getStatusIcon('New');
      }
    }
  }
} 