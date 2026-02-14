# Research: Multi-Tenant Media Broadcast Platform

**Date**: 2026-02-12  
**Feature**: [spec.md](spec.md)  
**Status**: Complete

## R-001: Multi-Tenant Architecture

**Decision**: Shared database with tenant scoping via `acts_as_tenant` gem + `default_scope` на уровне моделей.

**Rationale**: Спецификация требует изоляцию данных пользователей (FR-001), но не предполагает отдельные базы данных для каждого тенанта. Подход "shared database, shared schema" с tenant scoping — оптимальный баланс простоты и изоляции для SaaS-платформы с начальной нагрузкой до 1000 пользователей.

**Alternatives considered**:
- **Separate databases per tenant**: Избыточно для текущего масштаба, сложная миграция, высокие операционные расходы.
- **Separate schemas (PostgreSQL)**: Умеренная изоляция, но усложняет миграции и кеширование.
- **Row-Level Security (PostgreSQL RLS)**: Хорошая изоляция на уровне БД, но усложняет отладку и тестирование; может быть добавлена позже как дополнительный уровень защиты.

**Implementation approach**:
- Gem `acts_as_tenant` — автоматический scoping по `tenant_id` / `user_id`.
- Каждая пользовательская модель (MediaFile, Playlist, Transaction, Bid) принадлежит User.
- Административные модели (BroadcastDevice, DeviceGroup, TimeSlot) — глобальные, доступ через Pundit policies.
- `current_tenant` устанавливается в `ApplicationController` на основе аутентифицированного пользователя.

---

## R-002: Media File Storage and Processing

**Decision**: Active Storage с S3-совместимым бэкендом (MinIO для разработки, AWS S3 для production) + Direct Upload.

**Rationale**: Active Storage — встроенное решение Rails 8, поддерживает Direct Upload (файлы идут напрямую в S3, не через сервер приложения), что критично для файлов до 100 МБ (FR-003, SC-011). Обработка медиа — через Sidekiq jobs.

**Alternatives considered**:
- **Shrine**: Более гибкий, но избыточен для текущих требований. Нет встроенной интеграции с Rails forms/Turbo.
- **CarrierWave**: Устаревший подход, не поддерживает Direct Upload нативно.
- **Custom S3 upload**: Полный контроль, но дублирует функционал Active Storage.

**Implementation approach**:
- `has_one_attached :file` в модели MediaFile.
- Direct Upload через `@rails/activestorage` JavaScript + Stimulus controller для прогресс-бара.
- Валидация на стороне клиента (тип, размер) + серверная валидация через custom validator.
- `MediaProcessingJob` (Sidekiq) — извлечение метаданных (длительность, формат, разрешение) через `ffprobe` / gem `streamio-ffmpeg`.
- Поддерживаемые форматы: MP4, AVI, MOV (видео); MP3, AAC, WAV (аудио) — FR-003, FR-024.
- Максимальный размер: 100 МБ — FR-003.
- Валидация целостности файла: проверка заголовков и возможность декодирования (edge case: corrupted files).

---

## R-003: Auction System Design

**Decision**: Optimistic locking + database-level constraints для конкурентных ставок. Sidekiq Scheduler для автоматического закрытия аукционов.

**Rationale**: Аукционная система (FR-016..FR-018, FR-025) требует атомарности при обработке конкурентных ставок. Optimistic locking через `lock_version` предотвращает race conditions при одновременных ставках. PostgreSQL advisory locks — для критических секций при закрытии аукциона.

**Alternatives considered**:
- **Pessimistic locking (SELECT FOR UPDATE)**: Надёжно, но создаёт contention при высокой конкуренции. Может быть использовано для закрытия аукциона.
- **Event sourcing**: Избыточно для текущего масштаба, значительно увеличивает сложность.
- **Redis-based locking (Redlock)**: Подходит для распределённых систем, но добавляет зависимость без необходимости при одном сервере приложения.

**Implementation approach**:
- `Auctions::BidService` — принимает ставку, проверяет: баланс пользователя (FR-022), ставка > текущей максимальной (FR-016), аукцион открыт.
- Транзакция PostgreSQL с `lock_version` (optimistic lock) на модели Auction.
- При конфликте — повторная попытка с актуальными данными (retry pattern).
- FR-025: при равных ставках побеждает первая по `created_at`.
- `AuctionCloseJob` — запускается по расписанию (sidekiq-scheduler / solid_queue), определяет победителя, списывает средства, создаёт ScheduledBroadcast.
- `OutbidNotificationJob` — уведомление перебитого пользователя через Turbo Streams (real-time) + email.
- Edge case: аукцион без ставок — слот остаётся свободным, доступен для прямой покупки по стартовой цене.

---

## R-004: Financial Transactions and Balance Management

**Decision**: PostgreSQL transactions с row-level locking для атомарности. Паттерн Double-Entry (упрощённый) для аудита.

**Rationale**: Финансовые операции (FR-019..FR-023) требуют абсолютной атомарности и консистентности. Баланс пользователя — критический ресурс, требует pessimistic locking при модификации. Transaction log — immutable append-only для аудита.

**Alternatives considered**:
- **Полный Double-Entry Bookkeeping**: Максимальная аудируемость, но избыточен для текущей модели (нет межпользовательских переводов).
- **Event Sourcing для баланса**: Надёжное восстановление состояния, но сложность не оправдана на старте.
- **Внешний платёжный шлюз**: Будет добавлен позже для пополнения баланса; текущая реализация — внутренний ledger.

**Implementation approach**:
- `User#balance` — денормализованное поле (decimal, precision: 12, scale: 2) + CHECK constraint `balance >= 0`.
- `Transaction` — immutable модель: `user_id`, `amount`, `transaction_type` (deposit/deduction), `description`, `reference_type`, `reference_id` (polymorphic — Auction, ScheduledBroadcast).
- `Billing::DepositService` — пополнение баланса в транзакции: создание Transaction + обновление User#balance.
- `Billing::DeductionService` — списание: `SELECT FOR UPDATE` на User, проверка баланса, создание Transaction, обновление balance.
- `Billing::BalanceCheckService` — проверка достаточности средств перед ставкой/бронированием.
- Database CHECK constraint: `ALTER TABLE users ADD CONSTRAINT positive_balance CHECK (balance >= 0)` — защита от отрицательного баланса на уровне БД.

---

## R-005: Device Communication Protocol

**Decision**: REST API с polling + WebSocket (Action Cable) для real-time обновлений расписания.

**Rationale**: Устройства трансляции (физические ТВ) должны получать актуальное расписание и медиаконтент. Polling — надёжный базовый механизм; Action Cable — для мгновенных обновлений расписания (SC-012: 95% трансляций начинаются вовремя ±30 секунд).

**Alternatives considered**:
- **Только polling**: Простота, но задержка до интервала опроса (не подходит для SC-012).
- **MQTT**: Идеально для IoT, но добавляет отдельный брокер и усложняет инфраструктуру.
- **Server-Sent Events (SSE)**: Однонаправленные, но достаточны для push расписания. Менее гибкие, чем WebSocket.

**Implementation approach**:
- Device API endpoint: `GET /api/v1/devices/:token/schedule` — текущее расписание с плейлистами и URL медиафайлов.
- Аутентификация устройств: уникальный API token при регистрации (не OAuth — устройства без UI).
- Action Cable channel `DeviceScheduleChannel` — push обновления при изменении расписания.
- Fallback: polling каждые 60 секунд, если WebSocket недоступен.
- Статус устройства: heartbeat ping каждые 30 секунд, offline если >2 минуты без ответа.

---

## R-006: Time Zone Handling

**Decision**: Все даты хранятся в UTC в PostgreSQL. Таймзона устройства хранится как строка IANA (например, `Europe/Moscow`). Конвертация — на уровне представления.

**Rationale**: FR-026 требует поддержки таймзон для устройств в разных городах. Хранение в UTC — стандартная практика, предотвращает ошибки при DST переходах. Каждое устройство имеет свою таймзону — слоты отображаются в локальном времени устройства.

**Alternatives considered**:
- **Хранить в локальном времени устройства**: Проблемы при сравнении слотов разных устройств, ошибки DST.
- **Единая таймзона платформы**: Не соответствует FR-026 — устройства в разных городах.

**Implementation approach**:
- `BroadcastDevice#time_zone` — строка IANA (`ActiveSupport::TimeZone`).
- `TimeSlot#start_time`, `TimeSlot#end_time` — `timestamp with time zone` в PostgreSQL (хранится UTC).
- Отображение в UI: `Time.use_zone(device.time_zone) { slot.start_time.strftime(...) }`.
- Генерация слотов: 48 слотов по 30 минут (00:00-23:30 в локальном времени устройства), конвертируются в UTC при сохранении.

---

## R-007: Notification System

**Decision**: Turbo Streams (real-time in-app) + Action Mailer (email) для критических уведомлений.

**Rationale**: FR-018 требует уведомления при перебитии ставки. Turbo Streams — нативный механизм Rails 8 для real-time обновлений без JavaScript. Email — fallback для пользователей не в сети.

**Implementation approach**:
- `Turbo::StreamsChannel` — broadcast обновлений аукциона подписчикам.
- `OutbidNotificationJob` — отправляет Turbo Stream + email через Action Mailer.
- Notification model (опционально, Phase 2) — хранение истории уведомлений.
- Типы уведомлений: outbid, auction_won, broadcast_scheduled, broadcast_started, low_balance.

---

## R-008: Authentication and Authorization

**Decision**: Devise для аутентификации + Pundit для авторизации. Отдельные роли: `user` (content creator) и `admin`.

**Rationale**: Спецификация предполагает email/password или OAuth2 (Assumptions). Devise — стандарт для Rails аутентификации. Pundit — легковесная авторизация через policy objects, хорошо сочетается с мультитенантностью.

**Alternatives considered**:
- **Rails 8 built-in authentication**: Минималистичный, но не поддерживает OAuth2, password reset flow и другие enterprise-фичи из коробки.
- **Doorkeeper (OAuth2 provider)**: Избыточно — нам не нужен OAuth2 provider, только consumer.
- **CanCanCan**: Менее гибкий, чем Pundit; централизованный Ability class плохо масштабируется.

**Implementation approach**:
- `User` модель с Devise (database_authenticatable, registerable, recoverable, rememberable, validatable).
- `User#role` — enum: `user`, `admin`.
- Admin namespace: `authenticate :user, ->(u) { u.admin? }` в routes.
- Pundit policies для каждого ресурса: проверка принадлежности (мультитенантность) + ролей.
- OAuth2 (OmniAuth) — Phase 2, когда потребуется.

---

## R-009: Background Job Processing

**Decision**: Solid Queue (Rails 8 default) как primary, с возможностью миграции на Sidekiq при необходимости.

**Rationale**: Rails 8 включает Solid Queue как дефолтный бэкенд для Active Job — хранит задачи в PostgreSQL, не требует отдельного Redis. Для текущего масштаба (1000 пользователей) достаточно. При росте нагрузки — миграция на Sidekiq + Redis.

**Alternatives considered**:
- **Sidekiq + Redis**: Более производительный, но добавляет Redis как зависимость. Оправдан при >10K jobs/min.
- **GoodJob**: PostgreSQL-based, хорошая альтернатива, но Solid Queue — стандарт Rails 8.
- **DelayedJob**: Устаревший, медленнее альтернатив.

**Implementation approach**:
- `config.active_job.queue_adapter = :solid_queue` (default Rails 8).
- Очереди: `default`, `media_processing` (long-running), `auctions` (time-critical), `notifications`, `broadcasts`.
- Приоритеты: auctions > broadcasts > notifications > media_processing.
- Мониторинг: Mission Control Jobs (Rails 8 built-in dashboard).
- Recurring jobs (расписание аукционов): `solid_queue` recurring tasks.

---

## R-010: Caching Strategy

**Decision**: Multi-level caching: Fragment caching (views) + Russian Doll caching + Low-level caching (Solid Cache / Redis).

**Rationale**: Требования к производительности (SC-002: <2s page load, SC-003: <200ms API) требуют агрессивного кеширования. Rails 8 Solid Cache — дефолтный кеш-стор на PostgreSQL.

**Implementation approach**:
- Fragment caching для: списков устройств, медиабиблиотеки, расписаний.
- Russian Doll caching: вложенные кеши `device > time_slots > auction`.
- Counter caches: `playlists_count` на User, `bids_count` на Auction.
- Solid Cache для session storage и Rails cache.
- Cache invalidation: через `touch: true` на ассоциациях.
- ETags для API responses (conditional GET).
