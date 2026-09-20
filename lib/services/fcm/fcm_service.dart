import 'package:flutter/material.dart';

/// No-op implementation when running without Firebase.
/// Manages local notifications only (handled by flutter_local_notifications).
class FCMService {
  FCMService();

  /// Initialises local notifications (handled by NotificationService).
  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    // No-op when Firebase is not configured
  }

  /// No-op when Firebase is not configured
  Future<void> registerToken(String uid) async {
    // No-op when Firebase is not configured
  }

  /// No-op when Firebase is not configured
  Future<void> removeToken(String uid) async {
    // No-op when Firebase is not configured
  }
}