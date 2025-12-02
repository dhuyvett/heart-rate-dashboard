import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'screens/device_selection_screen.dart';
import 'utils/app_logger.dart';

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
    final settingsAsync = ref.watch(settingsProvider);
    final brightness = settingsAsync.when(
      data: (settings) =>
          settings.darkMode ? Brightness.dark : Brightness.light,
      loading: () => Brightness.light,
      error: (error, stack) => Brightness.light,
    );

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

enum PermissionCheckState { checking, granted, denied, checkFailed }

class _InitialRouteResolverState extends State<InitialRouteResolver> {
  static final _logger = AppLogger.getLogger('InitialRouteResolver');
  static final _permLogger = AppLogger.getLogger('PermissionsHandler');
  PermissionCheckState _permissionState = PermissionCheckState.checking;
  bool _warningPrompted = false;

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

      // Log cleanup for debugging
      if (expiredSessions.isNotEmpty) {
        _logger.i('Auto-deleted ${expiredSessions.length} expired session(s)');
      }
    } catch (e, stackTrace) {
      // Log error but don't block app startup
      _logger.e(
        'Error during session cleanup',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Checks if required Bluetooth permissions are granted.
  Future<void> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Check Android permissions
        final bluetoothScan = await Permission.bluetoothScan.isGranted;
        final bluetoothConnect = await Permission.bluetoothConnect.isGranted;
        final location = await Permission.locationWhenInUse.isGranted;

        final hasPermissions = bluetoothScan && bluetoothConnect && location;
        _permissionState = hasPermissions
            ? PermissionCheckState.granted
            : PermissionCheckState.denied;
      } else if (Platform.isIOS) {
        // Check iOS permission
        final hasPermissions = await Permission.bluetooth.isGranted;
        _permissionState = hasPermissions
            ? PermissionCheckState.granted
            : PermissionCheckState.denied;
      } else {
        // Desktop platforms - assume permissions are granted
        _permissionState = PermissionCheckState.granted;
      }
    } catch (e) {
      _permLogger.e(
        'Permission check failed',
        error: e,
        stackTrace: StackTrace.current,
      );
      _permissionState = PermissionCheckState.checkFailed;
    }

    if (mounted) {
      setState(() {
        _permissionState = _permissionState;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();
      } else if (Platform.isIOS) {
        await Permission.bluetooth.request();
      }
    } catch (e, stackTrace) {
      _permLogger.e(
        'Permission request failed',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      await _checkPermissions();
    }
  }

  Future<void> _maybeShowDesktopWarning(BuildContext context) async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }
    if (_warningPrompted) return;
    _warningPrompted = true;
    final dialogContext = context;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('desktop_encryption_warning_shown') ?? false;
      if (shown || !mounted) {
        return;
      }

      bool dontShowAgain = false;
      if (!mounted) return;
      await showDialog<void>(
        // ignore: use_build_context_synchronously
        context: dialogContext,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Desktop Encryption Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'On desktop platforms, the database is stored unencrypted. '
                  'For maximum privacy, use the mobile app on Android or iOS.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Checkbox(
                          value: dontShowAgain,
                          onChanged: (value) {
                            setState(() {
                              dontShowAgain = value ?? false;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text("Don't show again")),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('I Understand'),
              ),
            ],
          );
        },
      );

      if (dontShowAgain && mounted) {
        await prefs.setBool('desktop_encryption_warning_shown', true);
        _logger.i('Desktop encryption warning acknowledged');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionState == PermissionCheckState.checking) {
      // Show loading screen while checking permissions
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Navigate to appropriate screen based on permission status
    if (_permissionState == PermissionCheckState.granted) {
      _maybeShowDesktopWarning(context);
      return const DeviceSelectionScreen();
    }

    if (_permissionState == PermissionCheckState.checkFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Unable to check permissions. Please restart the app or check device settings.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _checkPermissions,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Permission denied
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Bluetooth permission is required to connect to heart rate monitors.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Request Permission'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
