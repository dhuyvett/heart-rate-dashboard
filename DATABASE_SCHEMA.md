# Database Schema

Storage is local-only. Android/iOS use SQLCipher; desktop uses unencrypted SQLite.

## Tables

### workout_sessions
| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER | Primary key, autoincrement |
| start_time | INTEGER | Unix ms, required |
| end_time | INTEGER | Unix ms, nullable |
| device_name | TEXT | Required |
| name | TEXT | Required |
| avg_hr | INTEGER | Nullable |
| min_hr | INTEGER | Nullable |
| max_hr | INTEGER | Nullable |
| distance_meters | REAL | Nullable |
| track_speed_distance | INTEGER | 0/1, required, default 0 |

Indexes:
- `idx_session_start_time` on `start_time`

### heart_rate_readings
| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER | Primary key, autoincrement |
| session_id | INTEGER | FK to `workout_sessions.id`, required |
| timestamp | INTEGER | Unix ms, required |
| bpm | INTEGER | Required |

Indexes:
- `idx_hr_session_id` on `session_id`
- `idx_hr_timestamp` on `timestamp`

### gps_samples
| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER | Primary key, autoincrement |
| session_id | INTEGER | FK to `workout_sessions.id`, required |
| timestamp | INTEGER | Unix ms, required |
| speed_mps | REAL | Required |
| altitude_meters | REAL | Nullable |

Indexes:
- `idx_gps_session_id` on `session_id`
- `idx_gps_timestamp` on `timestamp`

### app_settings
| Column | Type | Notes |
| --- | --- | --- |
| key | TEXT | Primary key |
| value | TEXT | Nullable |

## Migrations
Database version: 4
- v2: add `workout_sessions.name`, backfill default names
- v3: add `workout_sessions.distance_meters`
- v4: add `workout_sessions.track_speed_distance`, add `gps_samples` table + indexes

Source of truth: `lib/services/database_service.dart`.
