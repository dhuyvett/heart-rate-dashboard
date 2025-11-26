import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'screens/permission_explanation_screen.dart';
import 'screens/device_selection_screen.dart';

void main() {
  // Wrap the entire app with ProviderScope to enable Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

/// Root application widget.
///
/// Sets up the MaterialApp with theme configuration including heart rate zone colors.
/// Determines the initial route based on permission status.
/// Uses ConsumerWidget to watch settings for dark mode.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final brightness = settings.darkMode ? Brightness.dark : Brightness.light;

    return MaterialApp(
      title: 'Heart Rate Dashboard',
      theme: ThemeData(
        // Use a blue color scheme that complements our zone colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          // Use brightness based on dark mode setting
          brightness: brightness,
        ),
        // Apply Material 3 design
        useMaterial3: true,

        // Configure app bar theme to use primary color
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),

        // Configure card theme for session statistics
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Determine initial route based on permissions
      home: const InitialRouteResolver(),
    );
  }
}

/// Resolves the initial route based on permission status.
///
/// Navigation flow:
/// 1. If permissions not granted -> PermissionExplanationScreen
/// 2. If permissions granted -> DeviceSelectionScreen
///
/// The PermissionExplanationScreen will auto-navigate to DeviceSelectionScreen
/// if permissions are already granted.
class InitialRouteResolver extends StatefulWidget {
  const InitialRouteResolver({super.key});

  @override
  State<InitialRouteResolver> createState() => _InitialRouteResolverState();
}

class _InitialRouteResolverState extends State<InitialRouteResolver> {
  bool _isChecking = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initializes the app by checking permissions and performing cleanup.
  Future<void> _initializeApp() async {
    // First, perform session cleanup based on retention settings
    await _performSessionCleanup();

    // Then check permissions
    await _checkPermissions();
  }

  /// Performs auto-deletion of old sessions based on retention settings.
  Future<void> _performSessionCleanup() async {
    try {
      final db = DatabaseService.instance;

      // Load retention days setting
      final retentionDaysString = await db.getSetting('session_retention_days');
      final retentionDays = retentionDaysString != null
          ? int.tryParse(retentionDaysString) ?? 30
          : 30;

      // Calculate cutoff date
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      // Find expired sessions
      final expiredSessions = await db.getSessionsOlderThan(cutoffDate);

      // Delete each expired session
      for (final session in expiredSessions) {
        if (session.id != null) {
          await db.deleteSession(session.id!);
        }
      }

      // Log cleanup for debugging (silent to user)
      if (expiredSessions.isNotEmpty) {
        // ignore: avoid_print
        print('Auto-deleted ${expiredSessions.length} expired session(s)');
      }
    } catch (e) {
      // Log error but don't block app startup
      // ignore: avoid_print
      print('Error during session cleanup: $e');
    }
  }

  /// Checks if required Bluetooth permissions are granted.
  Future<void> _checkPermissions() async {
    bool hasPermissions = false;

    try {
      if (Platform.isAndroid) {
        // Check Android permissions
        final bluetoothScan = await Permission.bluetoothScan.isGranted;
        final bluetoothConnect = await Permission.bluetoothConnect.isGranted;
        final location = await Permission.locationWhenInUse.isGranted;

        hasPermissions = bluetoothScan && bluetoothConnect && location;
      } else if (Platform.isIOS) {
        // Check iOS permission
        hasPermissions = await Permission.bluetooth.isGranted;
      } else {
        // Desktop platforms - assume permissions are granted
        hasPermissions = true;
      }
    } catch (e) {
      // If permission check fails, assume permissions not granted
      hasPermissions = false;
    }

    if (mounted) {
      setState(() {
        _hasPermissions = hasPermissions;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show loading screen while checking permissions
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Navigate to appropriate screen based on permission status
    if (_hasPermissions) {
      return const DeviceSelectionScreen();
    } else {
      return const PermissionExplanationScreen();
    }
  }
}
