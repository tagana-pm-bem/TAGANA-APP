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

## Table `devices`

Perangkat TAGANA. Satu user dapat memiliki banyak device, tetapi satu device hanya dimiliki satu user.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `device_code` | `text` |  Unique |
| `device_name` | `text` |  |
| `device_token_hash` | `text` |  |
| `firmware_version` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `registered_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `token_created_at` | `timestamptz` |  Nullable |

## Table `device_status`

Snapshot kondisi terbaru device untuk kebutuhan dashboard dan Supabase Realtime.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `device_id` | `uuid` | Primary |
| `status` | `device_status_type` |  |
| `water_level` | `numeric` |  Nullable |
| `battery_level` | `numeric` |  Nullable |
| `signal_strength` | `int4` |  Nullable |
| `is_flood_detected` | `bool` |  |
| `last_seen_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  |

## Table `sensor_readings`

Histori sensor. ESP32 mengirim data melalui Edge Function, bukan langsung dari Flutter.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `device_id` | `uuid` |  |
| `water_level` | `numeric` |  |
| `battery_level` | `numeric` |  Nullable |
| `signal_strength` | `int4` |  Nullable |
| `is_flood_detected` | `bool` |  |
| `latitude` | `numeric` |  Nullable |
| `longitude` | `numeric` |  Nullable |
| `recorded_at` | `timestamptz` |  |

## Table `notifications`

Notifikasi user berdasarkan event dari device.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `device_id` | `uuid` |  Nullable |
| `type` | `notification_type` |  |
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

### `device_status_type`

`online` | `offline` | `warning` | `critical`

### `notification_type`

`flood_warning` | `high_water` | `low_battery` | `device_offline` | `device_online` | `system`

## RLS Policies

### `user_profiles`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can update their own profile` | UPDATE | authenticated | PERMISSIVE | `(id = auth.uid())` | `(id = auth.uid())` |
| `Users can view their own profile` | SELECT | authenticated | PERMISSIVE | `(id = auth.uid())` | — |

### `device_locations`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can view their device locations` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = device_locations.device_id) AND (d.user_id = auth.uid()))))` | — |

### `device_activities`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can view their device activities` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = device_activities.device_id) AND (d.user_id = auth.uid()))))` | — |

### `alerts`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can view their alerts` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = alerts.device_id) AND (d.user_id = auth.uid()))))` | — |

### `device_status`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can update their device status` | UPDATE | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = device_status.device_id) AND (d.user_id = auth.uid()))))` | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = device_status.device_id) AND (d.user_id = auth.uid()))))` |
| `Users can view their device status` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = device_status.device_id) AND (d.user_id = auth.uid()))))` | — |

### `sensor_readings`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can view their sensor readings` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM devices d   WHERE ((d.id = sensor_readings.device_id) AND (d.user_id = auth.uid()))))` | — |

### `notifications`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can delete their notifications` | DELETE | authenticated | PERMISSIVE | `(user_id = auth.uid())` | — |
| `Users can update their notifications` | UPDATE | authenticated | PERMISSIVE | `(user_id = auth.uid())` | `(user_id = auth.uid())` |
| `Users can view their notifications` | SELECT | authenticated | PERMISSIVE | `(user_id = auth.uid())` | — |

### `devices`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can delete their own devices` | DELETE | authenticated | PERMISSIVE | `(user_id = auth.uid())` | — |
| `Users can update their own devices` | UPDATE | authenticated | PERMISSIVE | `(user_id = auth.uid())` | `(user_id = auth.uid())` |
| `Users can create their own devices` | INSERT | authenticated | PERMISSIVE | — | `(user_id = auth.uid())` |
| `Users can view their own devices` | SELECT | authenticated | PERMISSIVE | `(user_id = auth.uid())` | — |

