/// Represents a Bluetooth device discovered during scanning.
///
/// This includes both real BLE heart rate monitors and the special
/// "Demo Mode" device for testing without physical hardware.
class ScannedDevice {
  /// Unique identifier for this device.
  /// For BLE devices, this is the device's remote ID.
  /// For demo mode, this is "DEMO_MODE_DEVICE".
  final String id;

  /// Human-readable name of the device.
  /// For demo mode, this is "Demo Mode".
  final String name;

  /// Signal strength (RSSI) in dBm.
  /// Valid range: -100 (weakest) to 0 (strongest).
  /// For demo mode, this is always -30 (excellent signal).
  final int rssi;

  /// Whether this is the special demo mode device.
  /// Demo mode devices appear first in the device list.
  final bool isDemo;

  /// Creates a scanned device instance.
  const ScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isDemo = false,
  });

  /// Factory constructor for creating the demo mode device.
  factory ScannedDevice.demoMode() {
    return const ScannedDevice(
      id: 'DEMO_MODE_DEVICE',
      name: 'Demo Mode',
      rssi: -30, // Excellent signal strength
      isDemo: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScannedDevice &&
        other.id == id &&
        other.name == name &&
        other.rssi == rssi &&
        other.isDemo == isDemo;
  }

  @override
  int get hashCode => Object.hash(id, name, rssi, isDemo);

  @override
  String toString() {
    return 'ScannedDevice(id: $id, name: $name, rssi: $rssi, isDemo: $isDemo)';
  }
}
