import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reconnection_handler.dart';

/// Provider to expose the reconnection handler for injection and testing.
final reconnectionHandlerProvider = Provider<ReconnectionController>((ref) {
  return ReconnectionHandler.instance;
});
