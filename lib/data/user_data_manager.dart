import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class UserDataManager {
  static const String _fileName = 'user_data.json'; // File name unchanged

  // Load user data from binary file
  static Future<Map<String, dynamic>> loadUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        // Read binary data and decode it
        final Uint8List binaryData = await file.readAsBytes();
        final jsonString = utf8.decode(binaryData);
        return json.decode(jsonString);
      } else {
        // If file does not exist, load initial data from assets
        final jsonData = await rootBundle.loadString('assets/$_fileName');
        return json.decode(jsonData);
      }
    } catch (e) {
      print('Error loading user data: $e');
      return {};
    }
  }

  // Save user data in binary format
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      // Convert to JSON string and then to binary
      final jsonString = json.encode(data);
      final binaryData = utf8.encode(jsonString);

      // Write binary data to file
      await file.writeAsBytes(binaryData, flush: true);
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Clear user data file
  static Future<void> clearUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Update only the userProfile field in the user data
  static Future<void> updateUserProfile(String newProfile) async {
    try {
      final userData = await loadUserData(); // Load existing data
      userData['userProfile'] = newProfile;  // Update field
      await saveUserData(userData);          // Save back
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
}
