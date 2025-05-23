import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/models/report_model.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/utils/validators.dart';
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CreateReportScreen extends StatefulWidget {
  final ReportModel? reportToEdit;

  const CreateReportScreen({
    super.key, 
    this.reportToEdit,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  Uint8List? _imageBytes; // To store image bytes for preview and upload
  String? _imageName; // To store the name of the picked image for upload
  String? _existingPhotoUrl;
  Position? _locationData;
  bool _isLoading = false;
  String? _errorMessage;
  bool get _isEditMode => widget.reportToEdit != null;
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _descriptionController.text = widget.reportToEdit!.description;
      _locationController.text = widget.reportToEdit!.location;
      _existingPhotoUrl = widget.reportToEdit!.photoUrl;
      if (widget.reportToEdit!.latitude != 0 && widget.reportToEdit!.longitude != 0) {
        _locationData = Position(
          latitude: widget.reportToEdit!.latitude,
          longitude: widget.reportToEdit!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } else {
      _getLocation();
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Get device location
  Future<void> _getLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.locationPermissionDenied)),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission is denied, show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.locationPermissionDenied)),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied, please enable them in settings')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current position
      _locationData = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Set location description
      if (_locationData != null) {
        _locationController.text = 'Lat: ${_locationData!.latitude.toStringAsFixed(6)}, Lng: ${_locationData!.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Pick image from camera
  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name; // Keep original name for potential use
          _existingPhotoUrl = null; // Clear existing photo if new one is picked
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: ${e.toString()}')),
        );
      }
    }
  }
  
  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name; // Keep original name
          _existingPhotoUrl = null; // Clear existing photo if new one is picked
        });
      }
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }
  
  // Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppStrings.addPhoto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Option 1: Take Photo
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.takePhoto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capture a new photo using your camera',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Option 2: Gallery
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.photo_library, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.fromGallery,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose an existing photo from your gallery',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  // Submit report to Supabase
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      // Photo is required for new reports, optional for edits if one already exists
      if (!_isEditMode && _imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.photoRequired)),
        );
        return;
      }
      // If editing and no new image is picked, and no existing image, then it's an issue.
      if (_isEditMode && _imageBytes == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is required to update the report.')), // Or a different message
        );
        return;
      }
      
      if (_locationData == null && _locationController.text.isEmpty) { // Allow pre-filled location string in edit mode
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location data is required. Please enable location services or ensure it is set.')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        String photoUrl = _existingPhotoUrl ?? '';
        String oldPhotoPath = '';

        // 1. Upload new image if one is picked (_imageBytes will have data)
        if (_imageBytes != null) {
          // Use a consistent naming scheme, e.g., with a timestamp and png extension
          final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.png';
          
          if (_isEditMode && _existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
            try {
              final oldUri = Uri.parse(_existingPhotoUrl!);
              if (oldUri.pathSegments.isNotEmpty) {
                 // Extract the file name without user ID path prefix
                 oldPhotoPath = oldUri.pathSegments.last; 
              }
            } catch (e) {
              print('Error parsing old photo URL for path: $e');
            }
          }

          try {
            photoUrl = await SupabaseService.uploadFile(
              bucket: 'report_photos',
              path: fileName,
              file: _imageBytes!, // Use the bytes directly
              contentType: 'image/png', // Set a consistent content type or derive from _imageName
            );
          } catch (uploadError) {
            print('Error uploading file: $uploadError');
            
            // Show a more specific error message
            if (uploadError.toString().contains("403") || 
                uploadError.toString().contains("Unauthorized") ||
                uploadError.toString().contains("violates row-level security policy")) {
              throw Exception('Permission denied while uploading image. Please contact support.');
            } else {
              throw Exception('Failed to upload image: $uploadError');
            }
          }

          if (oldPhotoPath.isNotEmpty && oldPhotoPath != fileName) {
            try {
              // We just need to pass the filename as the service will prepend user ID
              await SupabaseService.deleteFile(bucket: 'report_photos', path: oldPhotoPath);
            } catch (e) {
              print('Error deleting old photo: $e'); 
              // Don't throw, just log. Deleting old file is not critical to report submission
            }
          }
        } else if (_isEditMode && _existingPhotoUrl != null) {
          // No new image picked, but in edit mode, so keep the existing photoUrl
          photoUrl = _existingPhotoUrl!;
        }
        
        final userId = SupabaseService.currentUser?.id;
        if (userId == null) {
          throw Exception('User not authenticated');
        }
        
        // Determine status and priority based on parameters
        String status = _isEditMode ? widget.reportToEdit!.status : 'New';
        
        final reportData = {
          'user_id': userId,
          'description': _descriptionController.text,
          'photo_url': photoUrl,
          'latitude': _locationData?.latitude ?? widget.reportToEdit?.latitude ?? 0.0,
          'longitude': _locationData?.longitude ?? widget.reportToEdit?.longitude ?? 0.0,
          'location': _locationController.text,
          'status': status,
        };
        
        if (_isEditMode) {
          // Update existing report
          await SupabaseService.updateRecord(
            table: 'reports',
            id: widget.reportToEdit!.id,
            data: reportData,
          );
        } else {
          // Create new report
          await SupabaseService.createRecord(
            table: 'reports',
            data: reportData,
          );
        }
        
        if (mounted) {
          String message = _isEditMode 
              ? 'Report updated successfully!' 
              : 'Report submitted successfully!';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          // Pop twice if coming from ReportDetailScreen -> CreateReportScreen (edit mode)
          // Pop once if creating a new report directly
          int popCount = _isEditMode ? 2 : 1;
          for (int i = 0; i < popCount; i++) {
            if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true); // Pass true to indicate success / need for refresh
            }
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting report: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade600,
                Colors.orange.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEditMode ? LucideIcons.fileEdit : LucideIcons.filePlus,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _isEditMode ? AppStrings.editReport : AppStrings.createReport,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Colors.orange,
                background: Colors.white,
                secondary: Colors.orange,
              ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                bool isLastStep = _currentStep == 2;
                if (isLastStep) {
                  _submitReport();
                } else {
                  setState(() {
                    _currentStep += 1;
                  });
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                }
              },
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                final isLastStep = _currentStep == 2;
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, 
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLastStep ? (_isEditMode ? AppStrings.updateStatus : AppStrings.submit) : 'Continue',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ).animate()
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuad),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Back', style: TextStyle(fontSize: 16)),
                        ).animate()
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuad),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Photo
                Step(
                  title: Text(
                    AppStrings.addPhoto,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentStep >= 0 ? Colors.orange : Colors.grey,
                    ),
                  ),
                  content: _buildPhotoStep(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 2: Description
                Step(
                  title: Text(
                    AppStrings.reportDescription,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentStep >= 1 ? Colors.orange : Colors.grey,
                    ),
                  ),
                  content: _buildDescriptionStep(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 3: Location
                Step(
                  title: Text(
                    AppStrings.location,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentStep >= 2 ? Colors.orange : Colors.grey,
                    ),
                  ),
                  content: _buildLocationStep(),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoStep() {
    return Column(
      children: [
        Text(
          _isEditMode ? 'Change photo (optional)' : 'Take a clear photo of the damage',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .slideX(begin: -0.2, end: 0, duration: const Duration(milliseconds: 300)),
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[100]!, Colors.grey[200]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _imageBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: const Text(
                              'Tap to change photo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isEditMode && _existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _existingPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Image could not be loaded',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: const Text(
                                  'Tap to change photo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.camera,
                                size: 48,
                                color: Colors.orange[600],
                              ),
                            ).animate()
                              .fadeIn(duration: const Duration(milliseconds: 600))
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ).animate()
                              .fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200))
                              .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400)),
                            const SizedBox(height: 8),
                            Text(
                              'Take a clear photo of the issue',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ).animate()
                              .fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 300))
                              .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400)),
                          ],
                        ),
            ),
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: const Duration(milliseconds: 500),
          ),
      ],
    );
  }

  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provide a detailed description of the issue',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .slideX(begin: -0.2, end: 0, duration: const Duration(milliseconds: 300)),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: AppStrings.reportDescriptionHint,
            fillColor: Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 6,
          validator: (value) => Validators.validateRequired(
            value,
            'Description',
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
          
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.info,
                color: Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Be specific about the issue to help technicians resolve it quickly.',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 200))
          .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Verify your current location',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCcw, size: 20),
              color: Colors.orange,
              onPressed: _getLocation,
              tooltip: 'Refresh location',
            ),
          ],
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .slideX(begin: -0.2, end: 0, duration: const Duration(milliseconds: 300)),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            prefixIcon: Icon(LucideIcons.mapPin, color: Colors.orange[600]),
            fillColor: Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          readOnly: true,
          validator: (value) => Validators.validateRequired(
            value,
            'Location',
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
        
        if (_locationData != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[100]!, Colors.grey[200]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.map,
                          size: 32,
                          color: Colors.orange[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Location Captured',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_locationData!.latitude.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Lng: ${_locationData!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 200))
            .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
          
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[800], fontSize: 14),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 300))
            .shake(duration: const Duration(milliseconds: 500)),
      ],
    );
  }
} 