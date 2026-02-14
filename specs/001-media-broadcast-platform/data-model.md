# Data Model: Multi-Tenant Media Broadcast Platform

**Date**: 2026-02-12  
**Feature**: [spec.md](spec.md)  
**Research**: [research.md](research.md)

## Entity Relationship Overview

```
User (1) ──── (N) MediaFile
User (1) ──── (N) Playlist
User (1) ──── (N) Bid
User (1) ──── (N) Transaction
User (1) ──── (N) ScheduledBroadcast

Playlist (1) ──── (N) PlaylistItem (N) ──── (1) MediaFile

BroadcastDevice (1) ──── (N) TimeSlot
BroadcastDevice (N) ──── (N) DeviceGroup  [through DeviceGroupMembership]

TimeSlot (1) ──── (0..1) Auction
TimeSlot (1) ──── (0..1) ScheduledBroadcast

Auction (1) ──── (N) Bid
Auction (1) ──── (0..1) ScheduledBroadcast

ScheduledBroadcast (N) ──── (1) Playlist
```

---

## Entities

### User

Представляет аккаунт пользователя (рекламодатель или администратор).  
**Источник**: Spec §Key Entities — User, FR-001, FR-019..FR-023, Research R-008.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | Первичный ключ |
| `email` | `string` | NOT NULL, UNIQUE, INDEX | Email для аутентификации (Devise) |
| `encrypted_password` | `string` | NOT NULL | Зашифрованный пароль (Devise) |
| `role` | `integer` | NOT NULL, DEFAULT 0 | Enum: 0=user, 1=admin |
| `balance` | `decimal(12,2)` | NOT NULL, DEFAULT 0, CHECK >= 0 | Текущий баланс (FR-019) |
| `first_name` | `string` | NOT NULL | Имя пользователя |
| `last_name` | `string` | NOT NULL | Фамилия пользователя |
| `company_name` | `string` | | Название компании (опционально) |
| `reset_password_token` | `string` | UNIQUE, INDEX | Devise |
| `reset_password_sent_at` | `datetime` | | Devise |
| `remember_created_at` | `datetime` | | Devise |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `email`: presence, uniqueness, format
- `role`: presence, inclusion in `[:user, :admin]`
- `balance`: numericality >= 0
- `first_name`, `last_name`: presence

**Associations**:
- `has_many :media_files, dependent: :destroy`
- `has_many :playlists, dependent: :destroy`
- `has_many :bids, dependent: :restrict_with_error`
- `has_many :transactions, dependent: :restrict_with_error`
- `has_many :scheduled_broadcasts, dependent: :restrict_with_error`

**Database constraints**:
- `CHECK (balance >= 0)` — предотвращает отрицательный баланс на уровне БД (Research R-004)

---

### MediaFile

Загруженный аудио или видео файл.  
**Источник**: Spec §Key Entities — Media File, FR-002..FR-003, FR-024, Research R-002.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `user_id` | `bigint` | NOT NULL, FK, INDEX | Владелец файла (FR-001) |
| `title` | `string` | NOT NULL | Название файла |
| `media_type` | `integer` | NOT NULL | Enum: 0=audio, 1=video |
| `format` | `string` | NOT NULL | Формат файла (mp4, avi, mov, mp3, aac, wav) |
| `duration` | `integer` | | Длительность в секундах (заполняется после обработки) |
| `file_size` | `bigint` | NOT NULL | Размер файла в байтах |
| `processing_status` | `integer` | NOT NULL, DEFAULT 0 | Enum: 0=pending, 1=processing, 2=ready, 3=failed |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `title`: presence
- `media_type`: presence, inclusion in `[:audio, :video]`
- `format`: presence, inclusion in `%w[mp4 avi mov mp3 aac wav]` (FR-024)
- `file_size`: numericality, <= 100 MB (FR-003)
- Active Storage attachment: content type validation

**Associations**:
- `belongs_to :user`
- `has_one_attached :file` (Active Storage — Research R-002)
- `has_many :playlist_items, dependent: :restrict_with_error`
- `has_many :playlists, through: :playlist_items`

**State transitions** (`processing_status`):
```
pending → processing → ready
pending → processing → failed
```

**Indexes**:
- `(user_id)` — tenant scoping queries
- `(user_id, media_type)` — filtered media library
- `(user_id, created_at)` — sorted listing

---

### Playlist

Упорядоченная коллекция медиафайлов для трансляции.  
**Источник**: Spec §Key Entities — Playlist, FR-004..FR-006.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `user_id` | `bigint` | NOT NULL, FK, INDEX | Владелец плейлиста |
| `name` | `string` | NOT NULL | Название плейлиста |
| `description` | `text` | | Описание |
| `total_duration` | `integer` | NOT NULL, DEFAULT 0 | Суммарная длительность в секундах (FR-006) |
| `items_count` | `integer` | NOT NULL, DEFAULT 0 | Counter cache |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `name`: presence, uniqueness (scope: `user_id`)
- `total_duration`: numericality >= 0

**Associations**:
- `belongs_to :user`
- `has_many :playlist_items, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :playlist`
- `has_many :media_files, through: :playlist_items`
- `has_many :scheduled_broadcasts, dependent: :restrict_with_error`

**Callbacks**:
- Пересчёт `total_duration` при добавлении/удалении/изменении PlaylistItem.

---

### PlaylistItem

Join-модель для связи Playlist → MediaFile с порядком.  
**Источник**: FR-005 (reorder items).

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `playlist_id` | `bigint` | NOT NULL, FK, INDEX | |
| `media_file_id` | `bigint` | NOT NULL, FK, INDEX | |
| `position` | `integer` | NOT NULL | Порядок в плейлисте (FR-005) |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `position`: presence, numericality > 0
- Uniqueness: `(playlist_id, position)` — один элемент на позицию
- Uniqueness: `(playlist_id, media_file_id)` — один файл на плейлист

**Associations**:
- `belongs_to :playlist, touch: true` (invalidates cache, triggers duration recalc)
- `belongs_to :media_file`

**Indexes**:
- `(playlist_id, position)` UNIQUE — уникальный порядок
- `(playlist_id, media_file_id)` UNIQUE — уникальный файл в плейлисте

---

### BroadcastDevice

Физическое устройство трансляции (ТВ) в торговой точке.  
**Источник**: Spec §Key Entities — Broadcast Device, FR-007..FR-009, FR-026, Research R-005, R-006.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `name` | `string` | NOT NULL | Название устройства |
| `city` | `string` | NOT NULL | Город (FR-008) |
| `address` | `string` | NOT NULL | Адрес (FR-008) |
| `time_zone` | `string` | NOT NULL, DEFAULT 'UTC' | IANA timezone (FR-026, Research R-006) |
| `status` | `integer` | NOT NULL, DEFAULT 0 | Enum: 0=offline, 1=online |
| `api_token` | `string` | NOT NULL, UNIQUE, INDEX | Токен устройства для API (Research R-005) |
| `last_heartbeat_at` | `datetime` | | Последний сигнал от устройства |
| `description` | `text` | | Описание / комментарий |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `name`, `city`, `address`: presence
- `time_zone`: presence, inclusion in `ActiveSupport::TimeZone` names
- `api_token`: presence, uniqueness (генерируется автоматически при создании)

**Associations**:
- `has_many :time_slots, dependent: :destroy`
- `has_many :device_group_memberships, dependent: :destroy`
- `has_many :device_groups, through: :device_group_memberships`

**Indexes**:
- `(city)` — фильтрация по городу
- `(status)` — фильтрация по статусу
- `(api_token)` UNIQUE — аутентификация устройств

---

### DeviceGroup

Группа устройств для организационных целей.  
**Источник**: Spec §Key Entities — Device Group, FR-014..FR-015.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `name` | `string` | NOT NULL, UNIQUE | Название группы |
| `description` | `text` | | Описание |
| `devices_count` | `integer` | NOT NULL, DEFAULT 0 | Counter cache |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `name`: presence, uniqueness

**Associations**:
- `has_many :device_group_memberships, dependent: :destroy`
- `has_many :broadcast_devices, through: :device_group_memberships`

---

### DeviceGroupMembership

Join-модель для связи BroadcastDevice ↔ DeviceGroup (many-to-many).  
**Источник**: FR-014 — устройство может входить в несколько групп.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `broadcast_device_id` | `bigint` | NOT NULL, FK, INDEX | |
| `device_group_id` | `bigint` | NOT NULL, FK, INDEX | |
| `created_at` | `datetime` | NOT NULL | |

**Validations**:
- Uniqueness: `(broadcast_device_id, device_group_id)`

**Associations**:
- `belongs_to :broadcast_device`
- `belongs_to :device_group, counter_cache: :devices_count`

**Indexes**:
- `(broadcast_device_id, device_group_id)` UNIQUE

---

### TimeSlot

30-минутный временной слот в расписании устройства.  
**Источник**: Spec §Key Entities — Time Slot, FR-009..FR-010.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `broadcast_device_id` | `bigint` | NOT NULL, FK, INDEX | Устройство |
| `start_time` | `datetime` | NOT NULL | Начало слота (UTC) |
| `end_time` | `datetime` | NOT NULL | Конец слота (UTC) |
| `starting_price` | `decimal(10,2)` | NOT NULL, DEFAULT 0 | Начальная цена аукциона (FR-010) |
| `slot_status` | `integer` | NOT NULL, DEFAULT 0 | Enum: 0=available, 1=auction_active, 2=sold, 3=broadcasting, 4=completed |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `start_time`, `end_time`: presence
- `end_time` > `start_time`
- Duration: `end_time - start_time == 30.minutes` (FR-009)
- `starting_price`: numericality >= 0
- Uniqueness: `(broadcast_device_id, start_time)` — не допускать пересечение слотов

**Associations**:
- `belongs_to :broadcast_device`
- `has_one :auction, dependent: :destroy`
- `has_one :scheduled_broadcast, dependent: :nullify`

**State transitions** (`slot_status`):
```
available → auction_active → sold → broadcasting → completed
available → sold (прямая покупка, если аукцион без ставок)
```

**Indexes**:
- `(broadcast_device_id, start_time)` UNIQUE — уникальность слота
- `(broadcast_device_id, slot_status)` — фильтрация доступных слотов
- `(start_time)` — запросы по времени

---

### Auction

Процесс торгов за временной слот.  
**Источник**: Spec §Key Entities — Auction, FR-016..FR-018, FR-025, Research R-003.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `time_slot_id` | `bigint` | NOT NULL, FK, UNIQUE, INDEX | Слот аукциона |
| `starting_price` | `decimal(10,2)` | NOT NULL | Стартовая цена (копия из TimeSlot) |
| `current_highest_bid` | `decimal(10,2)` | | Текущая максимальная ставка |
| `highest_bidder_id` | `bigint` | FK, INDEX | Текущий лидер |
| `closes_at` | `datetime` | NOT NULL | Время закрытия аукциона |
| `auction_status` | `integer` | NOT NULL, DEFAULT 0 | Enum: 0=open, 1=closed, 2=cancelled |
| `lock_version` | `integer` | NOT NULL, DEFAULT 0 | Optimistic locking (Research R-003) |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `time_slot_id`: presence, uniqueness
- `starting_price`: numericality > 0
- `closes_at`: presence, must be before `time_slot.start_time`
- `current_highest_bid`: numericality >= `starting_price` (when present)

**Associations**:
- `belongs_to :time_slot`
- `belongs_to :highest_bidder, class_name: 'User', optional: true`
- `has_many :bids, dependent: :restrict_with_error`

**State transitions** (`auction_status`):
```
open → closed (по расписанию или вручную)
open → cancelled (администратором)
```

**Indexes**:
- `(time_slot_id)` UNIQUE
- `(auction_status, closes_at)` — запросы аукционов для закрытия
- `(highest_bidder_id)` — аукционы пользователя

---

### Bid

Ставка пользователя в аукционе.  
**Источник**: Spec §Key Entities — Bid, FR-016, FR-025.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `auction_id` | `bigint` | NOT NULL, FK, INDEX | Аукцион |
| `user_id` | `bigint` | NOT NULL, FK, INDEX | Пользователь |
| `amount` | `decimal(10,2)` | NOT NULL | Сумма ставки |
| `created_at` | `datetime` | NOT NULL | Время ставки (FR-025: earliest wins on tie) |

**Validations**:
- `amount`: numericality > 0, must be > `auction.current_highest_bid` (or >= `auction.starting_price` for first bid)

**Associations**:
- `belongs_to :auction`
- `belongs_to :user`

**Indexes**:
- `(auction_id, amount DESC)` — быстрый поиск максимальной ставки
- `(auction_id, created_at)` — порядок ставок для FR-025
- `(user_id)` — ставки пользователя

---

### Transaction

Запись о финансовой операции (пополнение или списание).  
**Источник**: Spec §Key Entities — Transaction, FR-019..FR-023, Research R-004.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `user_id` | `bigint` | NOT NULL, FK, INDEX | Пользователь |
| `amount` | `decimal(12,2)` | NOT NULL | Сумма (положительная для deposit, отрицательная для deduction) |
| `transaction_type` | `integer` | NOT NULL | Enum: 0=deposit, 1=deduction |
| `description` | `string` | NOT NULL | Описание операции |
| `reference_type` | `string` | | Polymorphic reference (Auction, ScheduledBroadcast) |
| `reference_id` | `bigint` | | Polymorphic reference ID |
| `created_at` | `datetime` | NOT NULL | |

**Validations**:
- `amount`: numericality, != 0
- `transaction_type`: presence
- `description`: presence

**Associations**:
- `belongs_to :user`
- `belongs_to :reference, polymorphic: true, optional: true`

**Note**: Модель Transaction — immutable (append-only). Записи не обновляются и не удаляются (Research R-004).

**Indexes**:
- `(user_id, created_at DESC)` — история транзакций
- `(reference_type, reference_id)` — поиск по связанной сущности

---

### ScheduledBroadcast

Запланированная трансляция плейлиста в слоте устройства.  
**Источник**: Spec §Key Entities — Scheduled Broadcast, FR-012..FR-013.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `bigint` | PK, auto | |
| `user_id` | `bigint` | NOT NULL, FK, INDEX | Пользователь |
| `playlist_id` | `bigint` | NOT NULL, FK, INDEX | Плейлист |
| `time_slot_id` | `bigint` | NOT NULL, FK, UNIQUE, INDEX | Временной слот |
| `auction_id` | `bigint` | FK, INDEX | Аукцион (если через аукцион) |
| `broadcast_status` | `integer` | NOT NULL, DEFAULT 0 | Enum: 0=scheduled, 1=playing, 2=completed, 3=failed |
| `started_at` | `datetime` | | Фактическое время начала |
| `completed_at` | `datetime` | | Фактическое время завершения |
| `created_at` | `datetime` | NOT NULL | |
| `updated_at` | `datetime` | NOT NULL | |

**Validations**:
- `time_slot_id`: uniqueness — один broadcast на слот
- Playlist duration <= TimeSlot duration (FR-013)

**Associations**:
- `belongs_to :user`
- `belongs_to :playlist`
- `belongs_to :time_slot`
- `belongs_to :auction, optional: true`
- `has_many :transactions, as: :reference`

**State transitions** (`broadcast_status`):
```
scheduled → playing → completed
scheduled → playing → failed
scheduled → failed (устройство offline)
```

**Indexes**:
- `(time_slot_id)` UNIQUE
- `(user_id, broadcast_status)` — трансляции пользователя по статусу
- `(broadcast_status, time_slot_id)` — поиск активных трансляций

---

## Database Constraints Summary

| Constraint | Table | Type | Description |
|-----------|-------|------|-------------|
| `positive_balance` | `users` | CHECK | `balance >= 0` |
| `unique_slot_per_device` | `time_slots` | UNIQUE | `(broadcast_device_id, start_time)` |
| `unique_auction_per_slot` | `auctions` | UNIQUE | `(time_slot_id)` |
| `unique_broadcast_per_slot` | `scheduled_broadcasts` | UNIQUE | `(time_slot_id)` |
| `unique_item_position` | `playlist_items` | UNIQUE | `(playlist_id, position)` |
| `unique_item_file` | `playlist_items` | UNIQUE | `(playlist_id, media_file_id)` |
| `unique_device_group` | `device_group_memberships` | UNIQUE | `(broadcast_device_id, device_group_id)` |
| All FK columns | all tables | INDEX | Foreign key indexes for join performance |
