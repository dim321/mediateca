# API Contract: Admin Endpoints

**Date**: 2026-02-12  
**Feature**: [spec.md](../spec.md)  
**Base URL**: `/admin` (HTML/Turbo) or `/api/v1/admin` (JSON)

> Административный интерфейс для управления устройствами, группами и расписаниями. Доступен только пользователям с ролью `admin` (FR-007).

---

## Device Management (FR-007, FR-008)

### GET /admin/devices
**Description**: Список всех устройств  
**Auth**: Required (admin)  
**Query params**:
- `city` (optional): фильтр по городу
- `status` (optional): `online` | `offline`
- `group_id` (optional): фильтр по группе (FR-015)
- `page`, `per_page`

**Response 200**:
```json
{
  "devices": [
    {
      "id": 1,
      "name": "ТВ-001 Вход",
      "city": "Москва",
      "address": "ул. Тверская, д. 1",
      "time_zone": "Europe/Moscow",
      "status": "online",
      "last_heartbeat_at": "2026-02-12T10:30:00Z",
      "groups": [
        { "id": 1, "name": "Тверская — Супермаркет" }
      ]
    }
  ],
  "meta": { "current_page": 1, "total_pages": 3, "total_count": 45 }
}
```

### POST /admin/devices
**Description**: Регистрация нового устройства (FR-008)  
**Auth**: Required (admin)  
**Request**:
```json
{
  "broadcast_device": {
    "name": "ТВ-001 Вход",
    "city": "Москва",
    "address": "ул. Тверская, д. 1",
    "time_zone": "Europe/Moscow",
    "description": "Основной экран у входа"
  }
}
```
**Response 201**:
```json
{
  "device": {
    "id": 1,
    "name": "ТВ-001 Вход",
    "city": "Москва",
    "address": "ул. Тверская, д. 1",
    "time_zone": "Europe/Moscow",
    "status": "offline",
    "api_token": "generated_token_shown_once",
    "created_at": "2026-02-12T12:00:00Z"
  }
}
```
**Response 422** (FR-008 — missing fields):
```json
{
  "errors": {
    "name": ["can't be blank"],
    "city": ["can't be blank"],
    "address": ["can't be blank"]
  }
}
```

### GET /admin/devices/:id
**Description**: Детали устройства  
**Auth**: Required (admin)

### PATCH /admin/devices/:id
**Description**: Обновление устройства  
**Auth**: Required (admin)

### DELETE /admin/devices/:id
**Description**: Удаление устройства  
**Auth**: Required (admin)  
**Response 422** (устройство с запланированными трансляциями):
```json
{
  "errors": {
    "base": ["Cannot delete device with scheduled broadcasts. Cancel broadcasts first."]
  }
}
```

---

## Time Slot Management (FR-009, FR-010)

### GET /admin/devices/:device_id/time_slots
**Description**: Расписание устройства (FR-009)  
**Auth**: Required (admin)  
**Query params**:
- `date` (required): дата (YYYY-MM-DD)

**Response 200**:
```json
{
  "device": { "id": 1, "name": "ТВ-001 Вход", "time_zone": "Europe/Moscow" },
  "date": "2026-02-15",
  "time_slots": [
    {
      "id": 1,
      "start_time": "2026-02-15T00:00:00+03:00",
      "end_time": "2026-02-15T00:30:00+03:00",
      "starting_price": "100.00",
      "slot_status": "available",
      "auction": null,
      "broadcast": null
    }
  ]
}
```

### POST /admin/devices/:device_id/time_slots/generate
**Description**: Генерация слотов на дату (48 слотов × 30 минут) (FR-009)  
**Auth**: Required (admin)  
**Request**:
```json
{
  "date": "2026-02-15",
  "default_starting_price": "500.00"
}
```
**Response 201**:
```json
{
  "generated_slots": 48,
  "date": "2026-02-15"
}
```
**Response 422** (slots already exist for date):
```json
{
  "errors": {
    "date": ["Time slots already exist for 2026-02-15"]
  }
}
```

### PATCH /admin/time_slots/:id
**Description**: Установка цены для слота (FR-010)  
**Auth**: Required (admin)  
**Request**:
```json
{
  "time_slot": {
    "starting_price": "1500.00"
  }
}
```
**Response 200**: Updated time slot  
**Response 422** (slot already has active auction):
```json
{
  "errors": {
    "starting_price": ["Cannot change price for slot with active auction"]
  }
}
```

### POST /admin/time_slots/:id/create_auction
**Description**: Создание аукциона для слота  
**Auth**: Required (admin)  
**Request**:
```json
{
  "auction": {
    "closes_at": "2026-02-15T06:00:00+03:00"
  }
}
```
**Response 201**: Created auction  
**Response 422**:
```json
{
  "errors": {
    "closes_at": ["must be before time slot start time"]
  }
}
```

---

## Device Group Management (FR-014, FR-015)

### GET /admin/device_groups
**Description**: Список групп устройств  
**Auth**: Required (admin)

**Response 200**:
```json
{
  "device_groups": [
    {
      "id": 1,
      "name": "Тверская — Супермаркет",
      "description": "Все экраны в супермаркете на Тверской",
      "devices_count": 5
    }
  ]
}
```

### POST /admin/device_groups
**Description**: Создание группы (FR-014)  
**Auth**: Required (admin)  
**Request**:
```json
{
  "device_group": {
    "name": "Тверская — Супермаркет",
    "description": "Все экраны в супермаркете на Тверской"
  }
}
```

### GET /admin/device_groups/:id
**Description**: Группа с устройствами  
**Auth**: Required (admin)

**Response 200**:
```json
{
  "device_group": {
    "id": 1,
    "name": "Тверская — Супермаркет",
    "description": "Все экраны в супермаркете на Тверской",
    "devices_count": 5,
    "devices": [
      {
        "id": 1,
        "name": "ТВ-001 Вход",
        "city": "Москва",
        "status": "online"
      }
    ]
  }
}
```

### PATCH /admin/device_groups/:id
**Description**: Обновление группы  
**Auth**: Required (admin)

### DELETE /admin/device_groups/:id
**Description**: Удаление группы (устройства НЕ удаляются — User Story 4, Scenario 4)  
**Auth**: Required (admin)  
**Response 200**:
```json
{
  "message": "Group deleted. 5 devices were removed from group but remain registered."
}
```

### POST /admin/device_groups/:id/add_devices
**Description**: Добавление устройств в группу (FR-014)  
**Auth**: Required (admin)  
**Request**:
```json
{
  "device_ids": [1, 2, 3]
}
```

### DELETE /admin/device_groups/:id/remove_device/:device_id
**Description**: Удаление устройства из группы (User Story 4, Scenario 3)  
**Auth**: Required (admin)  
**Response 200**: Device removed from group
