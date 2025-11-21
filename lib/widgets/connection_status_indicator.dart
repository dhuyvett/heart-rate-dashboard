import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart' as bt_service;

/// A visual indicator showing the current Bluetooth connection status.
///
/// Displays a colored dot that reflects the connection state:
/// - Green: Connected
/// - Yellow: Reconnecting (with pulsing animation)
/// - Red: Disconnected
///
/// The indicator includes a subtle pulsing animation when reconnecting
/// to draw attention to the temporary connection issue.
class ConnectionStatusIndicator extends StatelessWidget {
  /// The current connection state to display.
  final bt_service.ConnectionState connectionState;

  /// Creates a connection status indicator.
  const ConnectionStatusIndicator({required this.connectionState, super.key});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForState();
    final isPulsing =
        connectionState == bt_service.ConnectionState.reconnecting;

    return SizedBox(
      width: 12,
      height: 12,
      child: isPulsing
          ? _PulsingDot(color: color)
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
    );
  }

  /// Returns the appropriate color for the current connection state.
  Color _getColorForState() {
    switch (connectionState) {
      case bt_service.ConnectionState.connected:
        return Colors.green;
      case bt_service.ConnectionState.reconnecting:
      case bt_service.ConnectionState.connecting:
        return Colors.yellow;
      case bt_service.ConnectionState.disconnected:
        return Colors.red;
    }
  }
}

/// A pulsing dot widget for the reconnecting state.
///
/// Animates the dot's opacity and scale to create a pulsing effect
/// that draws attention to the reconnection attempt.
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: 0.8 + (_animation.value * 0.2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
