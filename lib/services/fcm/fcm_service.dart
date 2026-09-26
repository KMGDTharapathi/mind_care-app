import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Manages Firebase Cloud Messaging: permission requests, foreground message
/// display, notification-tap navigation, and FCM token lifecycle in Firestore.
class FCMService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  FCMService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialises FCM:
  /// - Requests notification permissions.
  /// - Sets up a foreground message listener that shows an in-app [SnackBar].
  /// - Sets up a background-tap listener ([onMessageOpenedApp]) that navigates
  ///   to the route specified in `message.data['route']`, defaulting to `/home`.
  /// - Checks [getInitialMessage] for notifications that launched the app from
  ///   a terminated state and applies the same navigation logic.
  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCMService: requestPermission failed: $e');
    }

    // Foreground messages — show an in-app SnackBar.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        final title = message.notification?.title ?? '';
        final body = message.notification?.body ?? '';
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (body.isNotEmpty) Text(body),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('FCMService: foreground message handler error: $e');
      }
    });

    // Background notification taps — navigate when app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      try {
        _navigateFromMessage(message, navigatorKey);
      } catch (e) {
        debugPrint('FCMService: onMessageOpenedApp handler error: $e');
      }
    });

    // Terminated-state launch — check for a notification that opened the app.
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _navigateFromMessage(initialMessage, navigatorKey);
      }
    } catch (e) {
      debugPrint('FCMService: getInitialMessage failed: $e');
    }
  }

  /// Navigates to the route specified in [message.data['route']], or `/home`
  /// if no route is provided.
  void _navigateFromMessage(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final route = message.data['route'] as String? ?? '/home';
    navigatorKey.currentState?.pushNamed(route);
  }

  /// Retrieves the current FCM token and writes it to Firestore at
  /// `/users/{uid}/fcm_tokens/{token}` with `platform` and `updatedAt`.
  ///
  /// Also subscribes to [FirebaseMessaging.instance.onTokenRefresh] so the
  /// stored token stays current when FCM rotates it.
  Future<void> registerToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _writeToken(uid, token);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await _writeToken(uid, newToken);
        } catch (e) {
          debugPrint('FCMService: onTokenRefresh write failed: $e');
        }
      });
    } catch (e) {
      debugPrint('FCMService: registerToken failed: $e');
    }
  }

  /// Writes a single FCM token document to Firestore.
  Future<void> _writeToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'platform': Platform.operatingSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Retrieves the current FCM token and deletes its document from Firestore
  /// at `/users/{uid}/fcm_tokens/{token}`.
  Future<void> removeToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .doc(token)
            .delete();
      }
    } catch (e) {
      debugPrint('FCMService: removeToken failed: $e');
    }
  }
}
