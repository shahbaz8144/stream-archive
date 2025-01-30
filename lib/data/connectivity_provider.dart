// data/connectivity_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  ConnectivityProvider() {
    _initializeConnectivity();
  }

  bool get isOnline => _isOnline;

  ConnectivityResult get connectivityResult => _connectivityResult;

  void _initializeConnectivity() {
    // Check initial connectivity status
    Connectivity().checkConnectivity().then((result) {
      _connectivityResult = result as ConnectivityResult;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      _connectivityResult = result as ConnectivityResult;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }
}
