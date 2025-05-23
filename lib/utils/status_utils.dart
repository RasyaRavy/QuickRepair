import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utility class for handling report status styling consistently across the app
class StatusUtils {
  /// Get the icon to represent a specific status
  static IconData getStatusIcon(String status) {
    final lowercaseStatus = status.toLowerCase();
    
    if (lowercaseStatus == 'new') {
      return Icons.star_rounded; // More cute than fiber_new
    } else if (lowercaseStatus == 'assigned') {
      return Icons.person_rounded; // Friendlier person icon
    } else if (lowercaseStatus == 'inprogress' || lowercaseStatus == 'in progress') {
      return Icons.handyman_rounded; // Tools icon - more specific than build
    } else if (lowercaseStatus == 'completed' || lowercaseStatus == 'done') {
      return Icons.celebration; // Celebration icon - more fun than verified
    } else if (lowercaseStatus == 'cancelled' || lowercaseStatus == 'rejected') {
      return Icons.heart_broken; // More emotional than cancel
    } else {
      return Icons.emoji_objects_rounded; // Light bulb icon instead of help
    }
  }

  /// Get the color associated with a status
  static Color getStatusColor(String status) {
    final lowercaseStatus = status.toLowerCase();
    
    if (lowercaseStatus == 'new') {
      return const Color(0xFF4E8BFF); // Brighter blue
    } else if (lowercaseStatus == 'assigned') {
      return const Color(0xFFFFB74D); // Brighter amber
    } else if (lowercaseStatus == 'inprogress' || lowercaseStatus == 'in progress') {
      return const Color(0xFFFF9248); // Brighter deep orange
    } else if (lowercaseStatus == 'completed' || lowercaseStatus == 'done') {
      return const Color(0xFF66BB6A); // Brighter green
    } else if (lowercaseStatus == 'cancelled' || lowercaseStatus == 'rejected') {
      return const Color(0xFFFF5252); // Brighter red
    } else {
      return Colors.grey.shade400; // Lighter grey
    }
  }

  /// Generate a gradient background for status indicators
  static LinearGradient getStatusGradient(String status) {
    final baseColor = getStatusColor(status);
    final brightColor = _lightenColor(baseColor, 0.2);
    
    return LinearGradient(
      colors: [
        baseColor,
        brightColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Helper method to create lighter version of a color
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Create a Container with a beautifully styled status indicator
  static Widget buildStatusBadge(String status, {bool showIcon = true, double fontSize = 12}) {
    final color = getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: getStatusGradient(status),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            _buildAnimatedStatusIcon(status, color, fontSize + 4),
            const SizedBox(width: 6),
          ],
          Text(
            _normalizeStatusText(status),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  /// Create a chip with status styling for filters and selections
  static Widget buildStatusChip({
    required String status,
    required bool isSelected,
    required Function(bool) onSelected,
    bool showIcon = true,
  }) {
    final color = getStatusColor(status);
    
    return FilterChip(
      showCheckmark: false,
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            isSelected 
              ? _buildAnimatedStatusIcon(status, Colors.white, 16)
              : Icon(
                  getStatusIcon(status),
                  size: 16,
                  color: color,
                ),
            const SizedBox(width: 4),
          ],
          Text(_normalizeStatusText(status)),
        ],
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      backgroundColor: isSelected ? color : color.withOpacity(0.1),
      selectedColor: color,
      onSelected: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : color.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
    );
  }
  
  /// Create a status avatar to be used in list items
  static Widget buildStatusAvatar(String status, {double size = 40.0}) {
    final color = getStatusColor(status);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: getStatusGradient(status),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: _buildAnimatedStatusIcon(status, Colors.white, size * 0.5),
      ),
    );
  }

  /// Build an animated status icon
  static Widget _buildAnimatedStatusIcon(String status, Color color, double size) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.rotate(
          angle: math.pi * 2 * value * 0.05 * math.sin(value * math.pi),
          child: Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Icon(
              getStatusIcon(status),
              size: size,
              color: color == Colors.white ? Colors.white : Colors.white,
            ),
          ),
        );
      },
    );
  }

  /// Normalize status text for display
  static String _normalizeStatusText(String status) {
    // Convert to lowercase for case-insensitive comparison
    final lowercase = status.toLowerCase();
    
    if (lowercase == 'new') {
      return 'New';
    } else if (lowercase == 'assigned') {
      return 'Assigned';
    } else if (lowercase == 'in progress' || lowercase == 'inprogress') {
      return 'In Progress';
    } else if (lowercase == 'completed' || lowercase == 'done') {
      return 'Completed';
    } else if (lowercase == 'cancelled' || lowercase == 'rejected') {
      return 'Cancelled';
    } else {
      return status; // Return original if not recognized
    }
  }
} 