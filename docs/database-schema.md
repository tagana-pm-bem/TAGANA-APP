## Table `user_profiles`

Additional profile information for Supabase Auth users.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `text` |  |
| `phone` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `devices`

Registered TAGANA ESP32 devices.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `device_code` | `text` |  |
| `serial_number` | `text` |  Nullable |
| `hardware_version` | `text` |  Nullable |
| `firmware_version` | `text` |  Nullable |
| `installed_at` | `timestamptz` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `user_devices`

Many-to-many relationship between users and TAGANA devices.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `device_id` | `uuid` |  |
| `role` | `device_member_role` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `device_status`

Latest device telemetry/state used for realtime monitoring.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `device_id` | `uuid` | Primary |
| `water_level` | `numeric` |  Nullable |
| `is_flood_detected` | `bool` |  |
| `battery_level` | `numeric` |  Nullable |
| `signal_strength` | `int4` |  Nullable |
| `latitude` | `numeric` |  Nullable |
| `longitude` | `numeric` |  Nullable |
| `location_accuracy` | `numeric` |  Nullable |
| `is_online` | `bool` |  |
| `last_seen_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  |

## Table `sensor_readings`

Historical device telemetry data.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `device_id` | `uuid` |  |
| `water_level` | `numeric` |  Nullable |
| `is_flood_detected` | `bool` |  |
| `battery_level` | `numeric` |  Nullable |
| `signal_strength` | `int4` |  Nullable |
| `recorded_at` | `timestamptz` |  |

## Table `device_locations`

Historical GPS locations reported by TAGANA devices.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `device_id` | `uuid` |  |
| `latitude` | `numeric` |  |
| `longitude` | `numeric` |  |
| `accuracy` | `numeric` |  Nullable |
| `recorded_at` | `timestamptz` |  |

## Table `device_activities`

Activity/event log for TAGANA devices.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `device_id` | `uuid` |  |
| `type` | `device_activity_type` |  |
| `title` | `text` |  |
| `description` | `text` |  Nullable |
| `metadata` | `jsonb` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `alerts`

Alerts generated from device conditions.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `device_id` | `uuid` |  |
| `type` | `alert_type` |  |
| `severity` | `alert_severity` |  |
| `status` | `alert_status` |  |
| `value` | `numeric` |  Nullable |
| `threshold` | `numeric` |  Nullable |
| `message` | `text` |  |
| `triggered_at` | `timestamptz` |  |
| `resolved_at` | `timestamptz` |  Nullable |

## Table `notifications`

User-specific notifications generated from device events or alerts.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `device_id` | `uuid` |  Nullable |
| `alert_id` | `uuid` |  Nullable |
| `type` | `text` |  |
| `title` | `text` |  |
| `message` | `text` |  |
| `is_read` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `read_at` | `timestamptz` |  Nullable |

## Custom Types / Enums

### `alert_severity`

`info` | `warning` | `critical`

### `alert_status`

`active` | `resolved`

### `alert_type`

`high_water_level` | `flood_detected` | `low_battery` | `device_offline` | `connection_lost`

### `device_activity_type`

`device_registered` | `device_connected` | `device_disconnected` | `ble_connected` | `ble_disconnected` | `wifi_configured` | `wifi_connected` | `wifi_disconnected` | `data_sync` | `firmware_updated` | `network_reset` | `emergency_mode`

### `device_member_role`

`owner` | `member`

