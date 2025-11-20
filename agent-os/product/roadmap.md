# Product Roadmap

1. [ ] Local Database Setup — Implement encrypted local storage using Sqflite for workout data persistence with schema for heart rate readings, timestamps, and session metadata. Includes database versioning and migration support. `S`

2. [ ] Bluetooth Device Discovery — Build device scanning and pairing interface to discover nearby BLE heart rate monitors with visual connection status indicators and saved device preferences. `M`

3. [ ] Real-Time Heart Rate Display — Create main workout screen showing live heart rate data from connected BLE device with large, readable numbers, zone indicators (resting/moderate/intense), and connection status. `S`

4. [ ] Heart Rate Data Recording — Implement background service to continuously record heart rate readings to local database during workout sessions with configurable sampling rates and session management (start/stop/pause). `M`

5. [ ] Historical Data Visualization — Build chart screen displaying historical heart rate data using fl_chart with time-series line graphs, selectable date ranges, and zoom/pan interactions for detailed analysis. `L`

6. [ ] Workout Session Management — Create session list view showing all recorded workouts with summary statistics (duration, avg/max heart rate, date), ability to view session details, and delete individual sessions. `M`

7. [ ] CSV Export Functionality — Implement data export feature generating CSV files with all workout data (timestamps, heart rate readings, session metadata) and device file picker for saving to user-selected location. `S`

8. [ ] GPS Distance & Speed Tracking — Add GPS integration for outdoor activities capturing location points, calculating real-time speed/pace and total distance, with visual route display on map using flutter_map or similar offline-capable mapping. `L`

9. [ ] Multi-Metric Workout View — Create unified workout screen displaying simultaneous heart rate, speed, distance, and pace with customizable layout and metric visibility preferences stored locally. `M`

10. [ ] Activity Type Classification — Add ability to categorize workouts by type (run, bike, walk, other) with type-specific metrics and filtering in history view for analyzing performance by activity. `S`

11. [ ] Performance Trends Dashboard — Build analytics screen showing long-term trends across multiple metrics including average heart rate progression, distance totals by time period, and personal records with visual charts. `L`

12. [ ] Advanced Export Options — Extend export functionality to support GPX format for GPS data, filtering exports by date range or activity type, and automatic backup scheduling to user-specified local directories. `M`

> Notes
> - Order items by technical dependencies and product architecture
> - Each item should represent an end-to-end (frontend + backend) functional and testable feature
> - Items 1-7 represent MVP focused on heart rate monitoring
> - Items 8-9 add GPS capabilities for outdoor activity tracking
> - Items 10-12 enhance analytics and data management
> - All features maintain privacy-first, offline-first principles
> - No network communication or cloud services in any phase
