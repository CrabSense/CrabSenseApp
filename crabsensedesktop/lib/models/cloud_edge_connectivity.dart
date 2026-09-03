import 'package:flutter/material.dart';

enum ConnectivityLinkKind { cloud, edge }

extension ConnectivityLinkKindX on ConnectivityLinkKind {
  String get label => switch (this) {
        ConnectivityLinkKind.cloud => 'Cloud',
        ConnectivityLinkKind.edge => 'Edge',
      };

  IconData get icon => switch (this) {
        ConnectivityLinkKind.cloud => Icons.cloud_outlined,
        ConnectivityLinkKind.edge => Icons.router_outlined,
      };
}

enum ConnectivityLinkState { unknown, checking, connected, disconnected }

class ConnectivityLinkStatus {
  const ConnectivityLinkStatus({
    required this.kind,
    required this.state,
    required this.endpoint,
    this.latencyMs,
    this.lastChecked,
    this.message,
  });

  final ConnectivityLinkKind kind;
  final ConnectivityLinkState state;
  final String endpoint;
  final int? latencyMs;
  final String? lastChecked;
  final String? message;

  bool get isConnected => state == ConnectivityLinkState.connected;

  ConnectivityLinkStatus copyWith({
    ConnectivityLinkState? state,
    String? endpoint,
    int? latencyMs,
    String? lastChecked,
    String? message,
  }) =>
      ConnectivityLinkStatus(
        kind: kind,
        state: state ?? this.state,
        endpoint: endpoint ?? this.endpoint,
        latencyMs: latencyMs ?? this.latencyMs,
        lastChecked: lastChecked ?? this.lastChecked,
        message: message ?? this.message,
      );
}
