// lib/widgets/error_view.dart
//
// Reusable error widget — shows a user-friendly message and a Retry button.
//
// Handles ALL 5 error types required by Section 4.5:
//   ✅ SocketException      → "No Internet Connection"
//   ✅ TimeoutException     → "Request Timed Out"
//   ✅ ApiException         → "Server Error (statusCode)"
//   ✅ FormatException      → "Unexpected Data Format"
//   ✅ Generic Exception    → "An Unexpected Error Occurred"
//
// FIX: Replaced Dart record return type  (String, String)  with a private
// helper class _ErrorInfo — records require Dart >= 3.0 but some IDEs
// still flag them as errors. Using a class is safer and more compatible.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_exception.dart';

// Private helper — holds the three display values for each error type.
class _ErrorInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  const _ErrorInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  // Map exception → display info
  _ErrorInfo _parse() {
    if (error is SocketException) {
      return const _ErrorInfo(
        title: 'No Internet Connection',
        subtitle: 'Please check your network settings and try again.',
        icon: Icons.wifi_off_rounded,
      );
    }
    if (error is TimeoutException) {
      return const _ErrorInfo(
        title: 'Request Timed Out',
        subtitle: 'The server took too long to respond. Please try again.',
        icon: Icons.timer_off_rounded,
      );
    }
    if (error is ApiException) {
      final ApiException e = error as ApiException;
      return _ErrorInfo(
        title: 'Server Error (${e.statusCode})',
        subtitle: e.message,
        icon: Icons.cloud_off_rounded,
      );
    }
    if (error is FormatException) {
      return const _ErrorInfo(
        title: 'Unexpected Data Format',
        subtitle: 'The server returned data in an unexpected format.',
        icon: Icons.error_outline_rounded,
      );
    }
    return _ErrorInfo(
      title: 'An Unexpected Error Occurred',
      subtitle: error.toString(),
      icon: Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ErrorInfo info = _parse();
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, size: 40, color: cs.onErrorContainer),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              info.title,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              info.subtitle,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Retry button
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
