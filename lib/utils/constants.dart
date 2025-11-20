/// Application-wide constants for the workout tracker app.
///
/// This file contains BLE UUIDs, default values, and configuration constants
/// used throughout the application.
library;

/// Bluetooth Low Energy service UUID for Heart Rate Service (standard UUID).
/// This is the standard BLE service UUID that all compliant heart rate monitors
/// should advertise.
const String bleHrServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';

/// Bluetooth Low Energy characteristic UUID for Heart Rate Measurement.
/// This characteristic provides the actual heart rate readings in beats per minute.
const String bleHrMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';

/// Default user age for heart rate zone calculations.
/// Used when no age has been configured in settings.
const int defaultAge = 30;

/// Default chart time window in seconds.
/// Determines how many seconds of heart rate data to display in the line chart.
const int defaultChartWindowSeconds = 30;

/// Maximum number of reconnection attempts before showing failure dialog.
/// After this many failed attempts, the user is prompted to retry or select a different device.
const int maxReconnectionAttempts = 10;

/// Heart rate sampling interval in milliseconds.
/// Defines how frequently heart rate readings are recorded to the database.
const int hrSamplingIntervalMs = 1500;
