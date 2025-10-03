import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  
  /// Validate image file size
  static bool isValidImageSize(File file) {
    try {
      final fileSize = file.lengthSync();
      return fileSize <= maxImageSize;
    } catch (e) {
      return false;
    }
  }
  
  /// Validate image file extension
  static bool isValidImageExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return allowedExtensions.contains('.$extension');
  }
  
  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Pick image with validation
  static Future<XFile?> pickImage({
    required ImageSource source,
    double maxWidth = 1024.0,
    double maxHeight = 1024.0,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        // Validate file size
        final file = File(image.path);
        if (!isValidImageSize(file)) {
          throw Exception('Image file is too large. Maximum size is 5MB.');
        }
        
        // Validate file extension
        if (!isValidImageExtension(image.name)) {
          throw Exception('Invalid image format. Allowed formats: JPG, PNG, GIF, WebP');
        }
        
        return image;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Direct image picker - simpler alternative to showImagePickerOptions
  static Future<XFile?> pickImageDirect({
    required ImageSource source,
    double maxWidth = 1024.0,
    double maxHeight = 1024.0,
    int imageQuality = 85,
  }) async {
    try {
      final result = await pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Show image picker options
  static Future<XFile?> showImagePickerOptions(BuildContext context, {bool showRemoveOption = false, VoidCallback? onRemove}) async {
    try {
      final choice = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop('camera');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop('gallery');
                  },
                ),
                if (showRemoveOption && onRemove != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.of(context).pop('remove');
                    },
                  ),
              ],
            ),
          );
        },
      );
      
      // Handle the choice
      if (choice == 'remove') {
        onRemove?.call();
        return null;
      } else if (choice == 'camera') {
        try {
          final result = await pickImage(source: ImageSource.camera);
          return result;
        } catch (e) {
          rethrow;
        }
      } else if (choice == 'gallery') {
        try {
          final result = await pickImage(source: ImageSource.gallery);
          return result;
        } catch (e) {
          rethrow;
        }
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Create a circular profile image widget with error handling
  static Widget buildProfileImage({
    required double radius,
    String? imageUrl,
    File? selectedImage,
    Widget? fallbackIcon,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 2.0,
    VoidCallback? onTap,
    bool showErrorHandling = true,
  }) {
    // Determine if we have a background image
    final ImageProvider? backgroundImage = selectedImage != null
        ? FileImage(selectedImage)
        : (imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) as ImageProvider : null);

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade300,
        backgroundImage: backgroundImage,
        onBackgroundImageError: backgroundImage != null && showErrorHandling 
            ? (exception, stackTrace) {
                // Handle image loading errors
              } 
            : null,
        child: backgroundImage == null
            ? fallbackIcon ?? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
    );
  }
}
