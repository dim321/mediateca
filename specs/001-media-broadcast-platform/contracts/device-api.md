# API Contract: Device Communication Endpoints

**Date**: 2026-02-12  
**Feature**: [spec.md](../spec.md)  
**Base URL**: `/api/v1/device`  
**Research**: R-005 (Device Communication Protocol)

> API для физических устройств трансляции (ТВ). Аутентификация по API token.

---

## Authentication

Все запросы от устройств аутентифицируются через Bearer token в заголовке:
```
Authorization: Bearer <device_api_token>
```

---

## GET /api/v1/device/schedule
**Description**: Получение текущего расписания для устройства  
**Auth**: Required (device token)  
**Query params**:
- `date` (optional): дата (YYYY-MM-DD), default: today

**Response 200**:
```json
{
  "device_id": 1,
  "time_zone": "Europe/Moscow",
  "date": "2026-02-15",
  "schedule": [
    {
      "time_slot_id": 42,
      "start_time": "2026-02-15T07:30:00+03:00",
      "end_time": "2026-02-15T08:00:00+03:00",
      "broadcast": {
        "id": 1,
        "broadcast_status": "scheduled",
        "playlist": {
          "id": 1,
          "name": "Morning Promo",
          "total_duration": 1800,
          "items": [
            {
              "position": 1,
              "media_file": {
                "id": 1,
                "title": "Promo Video Q1",
                "media_type": "video",
                "format": "mp4",
                "duration": 120,
                "download_url": "https://storage.example.com/...",
                "download_url_expires_at": "2026-02-15T09:00:00Z"
              }
            }
          ]
        }
      }
    },
    {
      "time_slot_id": 43,
      "start_time": "2026-02-15T08:00:00+03:00",
      "end_time": "2026-02-15T08:30:00+03:00",
      "broadcast": null
    }
  ]
}
```

**Response 401**:
```json
{
  "error": "Invalid or expired device token"
}
```

---

## POST /api/v1/device/heartbeat
**Description**: Отправка heartbeat (статус устройства)  
**Auth**: Required (device token)  
**Request**:
```json
{
  "status": "online",
  "current_broadcast_id": 1,
  "playback_position": 45
}
```
**Response 200**:
```json
{
  "acknowledged": true,
  "server_time": "2026-02-15T07:35:00Z"
}
```

---

## POST /api/v1/device/broadcast_status
**Description**: Отчёт о статусе трансляции  
**Auth**: Required (device token)  
**Request**:
```json
{
  "broadcast_id": 1,
  "status": "playing",
  "started_at": "2026-02-15T07:30:05+03:00"
}
```
**Response 200**:
```json
{
  "acknowledged": true
}
```

Допустимые значения `status`: `playing`, `completed`, `failed`

---

## WebSocket: DeviceScheduleChannel

**Description**: Real-time обновления расписания (Research R-005)  
**Connection**: Action Cable WebSocket

### Subscribe
```json
{
  "command": "subscribe",
  "identifier": "{\"channel\":\"DeviceScheduleChannel\",\"device_token\":\"<token>\"}"
}
```

### Receive (schedule update push)
```json
{
  "type": "schedule_updated",
  "time_slot_id": 42,
  "broadcast": {
    "id": 2,
    "playlist": { "..." : "..." }
  }
}
```

### Receive (emergency cancel)
```json
{
  "type": "broadcast_cancelled",
  "time_slot_id": 42,
  "broadcast_id": 1
}
```
