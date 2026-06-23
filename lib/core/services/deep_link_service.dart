import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../app.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';

class DeepLinkService {
  DeepLinkService._privateConstructor();
  static final DeepLinkService instance = DeepLinkService._privateConstructor();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> init() async {
    _appLinks = AppLinks();

    // Handle initial link if app was closed
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to handle initial deep link: $e");
    }

    // Listen to incoming links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link stream error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Received deep link: $uri");

    // Check if it's the email verification link
    // e.g. https://pathway.iamscammer.com/auth/verify-email?token=xyz&email=abc
    if (uri.path == '/auth/verify-email') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];

      if (token != null && token.isNotEmpty && email != null && email.isNotEmpty) {
        // Capture the navigator before the async gap to avoid
        // use_build_context_synchronously lint warning.
        final navigator = globalNavigatorKey.currentState;
        if (navigator != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            navigator.push(
              MaterialPageRoute(
                builder: (_) => EmailVerificationScreen(
                  token: token,
                  email: email,
                ),
              ),
            );
          });
        } else {
          // Navigator not ready yet — wait a bit longer then try once more
          Future.delayed(const Duration(milliseconds: 1000), () {
            final nav = globalNavigatorKey.currentState;
            nav?.push(
              MaterialPageRoute(
                builder: (_) => EmailVerificationScreen(
                  token: token,
                  email: email,
                ),
              ),
            );
          });
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
