import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/theme_colors.dart';

void main() {
  // Wrap the entire app with ProviderScope to enable Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

/// Root application widget.
///
/// Sets up the MaterialApp with theme configuration including heart rate zone colors.
/// The initial route will be determined based on device connection status
/// (to be implemented in Task Group 6).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      theme: ThemeData(
        // Use a blue color scheme that complements our zone colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          // Ensure good contrast for text and UI elements
          brightness: Brightness.light,
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
      // Initial route will be configured in Task Group 6
      // For now, show a placeholder home screen
      home: const PlaceholderHomeScreen(),
    );
  }
}

/// Placeholder home screen to be replaced with proper navigation in Task Group 6.
///
/// This temporary screen ensures the app compiles and runs while the feature
/// is being developed incrementally.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Heart Rate Monitor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bluetooth heart rate monitoring feature is being implemented.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            // Display zone colors as a visual preview
            Wrap(
              spacing: 8,
              children: [
                _ZoneColorChip('Resting', ZoneColors.resting),
                _ZoneColorChip('Zone 1', ZoneColors.zone1),
                _ZoneColorChip('Zone 2', ZoneColors.zone2),
                _ZoneColorChip('Zone 3', ZoneColors.zone3),
                _ZoneColorChip('Zone 4', ZoneColors.zone4),
                _ZoneColorChip('Zone 5', ZoneColors.zone5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small widget to display a heart rate zone color chip.
class _ZoneColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ZoneColorChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: TextStyle(
        color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
