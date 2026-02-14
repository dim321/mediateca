# API Contract: User-Facing Endpoints

**Date**: 2026-02-12  
**Feature**: [spec.md](../spec.md)  
**Base URL**: `/api/v1` (JSON) or `/` (HTML/Turbo)

> Приложение — Rails монолит с серверным рендерингом (Hotwire). Ниже описаны как HTML-маршруты (user-facing), так и JSON API эндпоинты (для будущих интеграций и мобильных клиентов).

---

## Authentication

**Source**: Research R-008, Spec §Assumptions

### POST /users/sign_in
**Description**: Аутентификация пользователя (Devise)  
**Request**:
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```
**Response 200**:
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Ivan",
    "last_name": "Petrov",
    "role": "user",
    "balance": "1500.00"
  },
  "token": "jwt_token_here"
}
```
**Response 401**:
```json
{
  "error": "Invalid email or password"
}
```

### POST /users
**Description**: Регистрация нового пользователя  
**Request**:
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "Ivan",
    "last_name": "Petrov",
    "company_name": "ООО Реклама"
  }
}
```
**Response 201**: Created user object  
**Response 422**: Validation errors

---

## Media Files (FR-002, FR-003, FR-024)

### GET /media_files
**Description**: Список медиафайлов пользователя  
**Auth**: Required (user)  
**Query params**:
- `media_type` (optional): `audio` | `video`
- `page` (optional): номер страницы
- `per_page` (optional): элементов на страницу (default: 20)

**Response 200**:
```json
{
  "media_files": [
    {
      "id": 1,
      "title": "Promo Video Q1",
      "media_type": "video",
      "format": "mp4",
      "duration": 120,
      "file_size": 52428800,
      "processing_status": "ready",
      "file_url": "https://storage.example.com/...",
      "created_at": "2026-02-10T12:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 95
  }
}
```

### POST /media_files
**Description**: Загрузка медиафайла (через Active Storage Direct Upload)  
**Auth**: Required (user)  
**Request**:
```json
{
  "media_file": {
    "title": "Promo Video Q1",
    "file": "signed_blob_id_from_direct_upload"
  }
}
```
**Response 201**:
```json
{
  "media_file": {
    "id": 1,
    "title": "Promo Video Q1",
    "media_type": "video",
    "format": "mp4",
    "file_size": 52428800,
    "processing_status": "pending",
    "created_at": "2026-02-10T12:00:00Z"
  }
}
```
**Response 422** (FR-003):
```json
{
  "errors": {
    "file": ["must be one of: mp4, avi, mov, mp3, aac, wav"],
    "file_size": ["must be less than 100 MB"]
  }
}
```

### GET /media_files/:id
**Description**: Детали медиафайла  
**Auth**: Required (owner only)

### DELETE /media_files/:id
**Description**: Удаление медиафайла  
**Auth**: Required (owner only)  
**Response 422** (edge case: файл в активном плейлисте):
```json
{
  "errors": {
    "base": ["Cannot delete media file that is part of active playlists"]
  }
}
```

---

## Playlists (FR-004, FR-005, FR-006)

### GET /playlists
**Description**: Список плейлистов пользователя  
**Auth**: Required (user)

**Response 200**:
```json
{
  "playlists": [
    {
      "id": 1,
      "name": "Morning Promo",
      "description": "Утренняя рекламная кампания",
      "total_duration": 1800,
      "items_count": 5,
      "created_at": "2026-02-10T12:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "total_pages": 1, "total_count": 3 }
}
```

### POST /playlists
**Description**: Создание плейлиста  
**Auth**: Required (user)  
**Request**:
```json
{
  "playlist": {
    "name": "Morning Promo",
    "description": "Утренняя рекламная кампания"
  }
}
```
**Response 201**: Created playlist

### GET /playlists/:id
**Description**: Плейлист с элементами (FR-006: total duration)  
**Auth**: Required (owner only)

**Response 200**:
```json
{
  "playlist": {
    "id": 1,
    "name": "Morning Promo",
    "description": "Утренняя рекламная кампания",
    "total_duration": 1800,
    "items_count": 5,
    "items": [
      {
        "id": 1,
        "position": 1,
        "media_file": {
          "id": 1,
          "title": "Promo Video Q1",
          "media_type": "video",
          "format": "mp4",
          "duration": 120
        }
      }
    ]
  }
}
```

### PATCH /playlists/:id
**Description**: Обновление плейлиста  
**Auth**: Required (owner only)

### DELETE /playlists/:id
**Description**: Удаление плейлиста  
**Auth**: Required (owner only)

### POST /playlists/:playlist_id/items
**Description**: Добавление медиафайла в плейлист  
**Auth**: Required (owner only)  
**Request**:
```json
{
  "playlist_item": {
    "media_file_id": 1,
    "position": 3
  }
}
```

### PATCH /playlists/:playlist_id/items/:id
**Description**: Изменение позиции элемента (FR-005)  
**Auth**: Required (owner only)  
**Request**:
```json
{
  "playlist_item": {
    "position": 1
  }
}
```

### DELETE /playlists/:playlist_id/items/:id
**Description**: Удаление элемента из плейлиста  
**Auth**: Required (owner only)

### PATCH /playlists/:playlist_id/reorder
**Description**: Массовое переупорядочивание элементов (FR-005)  
**Auth**: Required (owner only)  
**Request**:
```json
{
  "item_ids": [3, 1, 5, 2, 4]
}
```
**Response 200**: Updated playlist with new order

---

## Devices & Schedules (FR-011)

### GET /devices
**Description**: Список доступных устройств (для пользователей)  
**Auth**: Required (user)  
**Query params**:
- `city` (optional): фильтр по городу
- `group_id` (optional): фильтр по группе (FR-015)

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
      "status": "online"
    }
  ]
}
```

### GET /devices/:id/schedule
**Description**: Расписание устройства со слотами (FR-011)  
**Auth**: Required (user)  
**Query params**:
- `date` (required): дата расписания (YYYY-MM-DD)

**Response 200**:
```json
{
  "device": {
    "id": 1,
    "name": "ТВ-001 Вход",
    "time_zone": "Europe/Moscow"
  },
  "time_slots": [
    {
      "id": 1,
      "start_time": "2026-02-15T07:00:00+03:00",
      "end_time": "2026-02-15T07:30:00+03:00",
      "slot_status": "available",
      "starting_price": "500.00",
      "auction": null
    },
    {
      "id": 2,
      "start_time": "2026-02-15T07:30:00+03:00",
      "end_time": "2026-02-15T08:00:00+03:00",
      "slot_status": "auction_active",
      "starting_price": "1000.00",
      "auction": {
        "id": 1,
        "current_highest_bid": "1500.00",
        "closes_at": "2026-02-15T06:00:00+03:00",
        "bids_count": 5
      }
    }
  ]
}
```

---

## Auctions & Bids (FR-016, FR-017, FR-018, FR-025)

### GET /auctions
**Description**: Список активных аукционов  
**Auth**: Required (user)  
**Query params**:
- `device_id` (optional): фильтр по устройству
- `status` (optional): `open` | `closed`

**Response 200**:
```json
{
  "auctions": [
    {
      "id": 1,
      "time_slot": {
        "id": 2,
        "start_time": "2026-02-15T07:30:00+03:00",
        "device": { "id": 1, "name": "ТВ-001 Вход", "city": "Москва" }
      },
      "starting_price": "1000.00",
      "current_highest_bid": "1500.00",
      "closes_at": "2026-02-15T06:00:00+03:00",
      "auction_status": "open",
      "my_highest_bid": "1200.00"
    }
  ]
}
```

### GET /auctions/:id
**Description**: Детали аукциона с историей ставок  
**Auth**: Required (user)

**Response 200**:
```json
{
  "auction": {
    "id": 1,
    "starting_price": "1000.00",
    "current_highest_bid": "1500.00",
    "closes_at": "2026-02-15T06:00:00+03:00",
    "auction_status": "open",
    "time_slot": { "..." : "..." },
    "bids": [
      {
        "id": 5,
        "amount": "1500.00",
        "user_name": "User***",
        "created_at": "2026-02-14T10:30:00Z"
      }
    ],
    "my_bids": [
      {
        "id": 3,
        "amount": "1200.00",
        "created_at": "2026-02-14T09:00:00Z"
      }
    ]
  }
}
```

### POST /auctions/:auction_id/bids
**Description**: Размещение ставки (FR-016)  
**Auth**: Required (user)  
**Request**:
```json
{
  "bid": {
    "amount": "2000.00"
  }
}
```
**Response 201**:
```json
{
  "bid": {
    "id": 6,
    "amount": "2000.00",
    "created_at": "2026-02-14T11:00:00Z"
  },
  "auction": {
    "current_highest_bid": "2000.00",
    "auction_status": "open"
  }
}
```
**Response 422** (FR-022 — insufficient funds):
```json
{
  "errors": {
    "amount": ["Insufficient balance. Current balance: 500.00, bid amount: 2000.00"]
  }
}
```
**Response 422** (bid too low):
```json
{
  "errors": {
    "amount": ["Must be higher than current highest bid (1500.00)"]
  }
}
```
**Response 409** (optimistic lock conflict):
```json
{
  "errors": {
    "base": ["Auction was updated by another user. Please refresh and try again."]
  }
}
```

---

## Scheduled Broadcasts (FR-012, FR-013)

### GET /broadcasts
**Description**: Список запланированных трансляций пользователя  
**Auth**: Required (user)  
**Query params**:
- `status` (optional): `scheduled` | `playing` | `completed` | `failed`

**Response 200**:
```json
{
  "broadcasts": [
    {
      "id": 1,
      "broadcast_status": "scheduled",
      "playlist": { "id": 1, "name": "Morning Promo", "total_duration": 1800 },
      "time_slot": {
        "id": 2,
        "start_time": "2026-02-15T07:30:00+03:00",
        "end_time": "2026-02-15T08:00:00+03:00"
      },
      "device": { "id": 1, "name": "ТВ-001 Вход", "city": "Москва" },
      "created_at": "2026-02-14T12:00:00Z"
    }
  ]
}
```

### POST /broadcasts
**Description**: Планирование трансляции (прямая покупка, не через аукцион) (FR-012)  
**Auth**: Required (user)  
**Request**:
```json
{
  "broadcast": {
    "playlist_id": 1,
    "time_slot_id": 2
  }
}
```
**Response 201**: Created broadcast  
**Response 422** (FR-013 — duration mismatch):
```json
{
  "errors": {
    "playlist": ["Duration (35 min) exceeds time slot duration (30 min)"]
  }
}
```

---

## Account Balance & Transactions (FR-019..FR-023)

### GET /balance
**Description**: Текущий баланс и история транзакций (FR-019, FR-023)  
**Auth**: Required (user)

**Response 200**:
```json
{
  "balance": "3500.00",
  "transactions": [
    {
      "id": 1,
      "amount": "5000.00",
      "transaction_type": "deposit",
      "description": "Пополнение баланса",
      "created_at": "2026-02-10T12:00:00Z"
    },
    {
      "id": 2,
      "amount": "-1500.00",
      "transaction_type": "deduction",
      "description": "Выигрыш аукциона #1 — ТВ-001, 15.02.2026 07:30",
      "reference_type": "Auction",
      "reference_id": 1,
      "created_at": "2026-02-14T12:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "total_pages": 1, "total_count": 2 }
}
```

### POST /balance/deposit
**Description**: Пополнение баланса (FR-020)  
**Auth**: Required (user)  
**Request**:
```json
{
  "deposit": {
    "amount": "5000.00"
  }
}
```
**Response 201**:
```json
{
  "transaction": {
    "id": 3,
    "amount": "5000.00",
    "transaction_type": "deposit",
    "description": "Пополнение баланса"
  },
  "new_balance": "8500.00"
}
```
**Response 422**:
```json
{
  "errors": {
    "amount": ["must be greater than 0"]
  }
}
```
