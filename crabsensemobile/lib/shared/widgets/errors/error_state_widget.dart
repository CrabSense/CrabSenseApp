import 'package:flutter/material.dart';

/// Error State Widget Component
/// Full-screen error display with retry capability
/// Requirements: 20.1-20.10, 21.6
class ErrorStateWidget extends StatelessWidget {
  /// Creates an error state widget
  const ErrorStateWidget({
    required this.message,
    super.key,
    this.title,
    this.icon,
    this.onRetry,
    this.retryButtonText = 'Retry',
    this.additionalActions,
  });

  /// Error message to display
  final String message;

  /// Optional error title
  final String? title;

  /// Optional custom icon
  final IconData? icon;

  /// Optional retry callback
  final VoidCallback? onRetry;

  /// Retry button text
  final String retryButtonText;

  /// Additional action buttons below retry
  final List<Widget>? additionalActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(icon ?? Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 24),

            // Error title
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            // Error message
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 32),

            // Retry button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText),
              ),

            // Additional actions
            if (additionalActions != null) ...[const SizedBox(height: 16), ...additionalActions!],
          ],
        ),
      ),
    );
  }
}

/// Empty State Widget Component
/// Full-screen empty state display
class EmptyStateWidget extends StatelessWidget {
  /// Creates an empty state widget
  const EmptyStateWidget({
    required this.message,
    super.key,
    this.title,
    this.icon,
    this.actionButton,
  });

  /// Empty state message
  final String message;

  /// Optional title
  final String? title;

  /// Optional custom icon
  final IconData? icon;

  /// Optional action button
  final Widget? actionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty icon
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),

            // Title
            if (title != null) ...[
              Text(title!, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionButton != null) ...[const SizedBox(height: 32), actionButton!],
          ],
        ),
      ),
    );
  }
}

/// Network Error Widget Component
/// Pre-configured error for network failures
class NetworkErrorWidget extends StatelessWidget {
  /// Creates a network error widget
  const NetworkErrorWidget({super.key, this.onRetry});

  /// Retry callback
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ErrorStateWidget(
    title: 'Connection Error',
    message:
        'Unable to connect to the server. Please check your internet connection and try again.',
    icon: Icons.wifi_off,
    onRetry: onRetry,
  );
}

/// Timeout Error Widget Component
/// Pre-configured error for timeout failures
class TimeoutErrorWidget extends StatelessWidget {
  /// Creates a timeout error widget
  const TimeoutErrorWidget({super.key, this.onRetry});

  /// Retry callback
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ErrorStateWidget(
    title: 'Request Timeout',
    message: 'The request took too long to complete. Please try again.',
    icon: Icons.access_time,
    onRetry: onRetry,
  );
}
