# Implementation Plan: Multi-Tenant Media Broadcast Platform

**Branch**: `001-media-broadcast-platform` | **Date**: 2026-02-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-media-broadcast-platform/spec.md`

## Summary

Мультитенантная SaaS-платформа для управления рекламными аудио/видео материалами и их трансляции на устройства (ТВ) в торговых точках. Пользователи загружают медиафайлы, создают плейлисты, выкупают временные слоты устройств через аукцион. Администраторы управляют устройствами и группами. Реализация на Ruby on Rails 8 с Hotwire (Turbo + Stimulus), PostgreSQL, Active Storage + S3-совместимое хранилище, Sidekiq для фоновых задач.

## Technical Context

**Language/Version**: Ruby 3.4.7 / Rails 8.0  
**Primary Dependencies**: Rails 8, Hotwire (Turbo + Stimulus), Tailwind CSS, Sidekiq, Active Storage, Devise, Pundit  
**Storage**: PostgreSQL 18 (основная БД), S3-совместимое хранилище (медиафайлы через Active Storage)  
**Testing**: RSpec, FactoryBot, Capybara, Shoulda Matchers, SimpleCov  
**Target Platform**: Linux server (Docker), веб-браузеры (десктоп + мобильные)  
**Project Type**: Web application (монолит Rails с отдельным admin namespace)  
**Performance Goals**: <2s загрузка страниц (p95), <200ms API ответ (p95), <1s обработка аукциона, 1000 одновременных пользователей  
**Constraints**: Файлы до 100 МБ, транзакции <500ms (p95), TDD обязателен, покрытие >80%  
**Scale/Scope**: 1000 одновременных пользователей, 10 основных моделей, ~20 экранов (user + admin)

## Constitution Check (Pre-Design)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality**: ✅ Ruby Style Guide + RuboCop обязателен. Монолит Rails с чётким разделением на namespaces (user/admin). Паттерн Service Objects для бизнес-логики (аукционы, транзакции). Single Responsibility для моделей и контроллеров.  
**Testing**: ✅ TDD обязателен (RSpec + FactoryBot). Покрытие >80%. Интеграционные тесты для: API эндпоинтов, пользовательских сценариев, аукционной механики, финансовых транзакций. System tests через Capybara.  
**UX Consistency**: ✅ Hotwire (Turbo Frames/Streams) для динамики без полных перезагрузок. Tailwind CSS для единообразного дизайна. Responsive design. WCAG 2.1 Level AA. Loading states для async операций (загрузка файлов, ставки).  
**Performance**: ✅ PostgreSQL с eager loading (includes/joins). Fragment caching + Russian Doll caching. Sidekiq для: обработки медиа, закрытия аукционов, уведомлений. Индексы для FK и часто используемых запросов. Active Storage Direct Upload для файлов.  
**Quality Gates**: ✅ RSpec (unit + integration + system), RuboCop (zero offenses), Brakeman (security), bundler-audit, SimpleCov (>80%).

*If any check fails, document justification in Complexity Tracking section below.*

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── application_controller.rb
│   ├── media_files_controller.rb
│   ├── playlists_controller.rb
│   ├── playlist_items_controller.rb
│   ├── devices_controller.rb
│   ├── schedules_controller.rb
│   ├── auctions_controller.rb
│   ├── bids_controller.rb
│   ├── broadcasts_controller.rb
│   ├── balances_controller.rb
│   ├── transactions_controller.rb
│   └── admin/
│       ├── base_controller.rb
│       ├── devices_controller.rb
│       ├── device_groups_controller.rb
│       └── time_slots_controller.rb
├── models/
│   ├── user.rb
│   ├── media_file.rb
│   ├── playlist.rb
│   ├── playlist_item.rb
│   ├── broadcast_device.rb
│   ├── device_group.rb
│   ├── device_group_membership.rb
│   ├── time_slot.rb
│   ├── auction.rb
│   ├── bid.rb
│   ├── scheduled_broadcast.rb
│   └── transaction.rb
├── services/
│   ├── media/
│   │   ├── upload_service.rb
│   │   └── validation_service.rb
│   ├── auctions/
│   │   ├── bid_service.rb
│   │   ├── close_auction_service.rb
│   │   └── notification_service.rb
│   ├── broadcasts/
│   │   ├── schedule_service.rb
│   │   └── playback_service.rb
│   └── billing/
│       ├── deposit_service.rb
│       ├── deduction_service.rb
│       └── balance_check_service.rb
├── jobs/
│   ├── auction_close_job.rb
│   ├── broadcast_start_job.rb
│   ├── media_processing_job.rb
│   └── outbid_notification_job.rb
├── views/
│   ├── layouts/
│   ├── media_files/
│   ├── playlists/
│   ├── devices/
│   ├── auctions/
│   ├── broadcasts/
│   ├── balances/
│   └── admin/
│       ├── devices/
│       ├── device_groups/
│       └── time_slots/
├── javascript/
│   └── controllers/          # Stimulus controllers
│       ├── upload_controller.js
│       ├── auction_controller.js
│       ├── playlist_sort_controller.js
│       └── schedule_controller.js
└── policies/                  # Pundit authorization
    ├── media_file_policy.rb
    ├── playlist_policy.rb
    ├── auction_policy.rb
    └── broadcast_policy.rb

config/
├── routes.rb
├── database.yml
├── storage.yml
└── sidekiq.yml

db/
└── migrate/

spec/
├── models/
├── services/
├── controllers/
├── requests/
├── system/
├── jobs/
├── policies/
├── factories/
└── support/
```

**Structure Decision**: Rails 8 монолит с namespace `Admin::` для административного интерфейса. Service Objects для бизнес-логики (media/, auctions/, broadcasts/, billing/). Pundit policies для авторизации. Sidekiq jobs для фоновых задач. Stimulus controllers для клиентских взаимодействий.

## Constitution Check (Post-Design)

*Re-evaluation after Phase 1 design completion.*

**Code Quality**: ✅ Архитектура подтверждена: Rails 8 монолит с чётким разделением ответственности. Service Objects (4 домена: media, auctions, broadcasts, billing) — каждый сервис выполняет одну задачу. Pundit policies для авторизации. Модели тонкие, логика в сервисах. RuboCop (rails-omakase) настроен.  
**Testing**: ✅ RSpec + FactoryBot. Покрытие всех уровней: unit (models, services, policies), request (controllers), system (Capybara), jobs. SimpleCov для метрики >80%. FactoryBot factories для 10 моделей. Database Cleaner для изоляции тестов.  
**UX Consistency**: ✅ Turbo Frames для навигации без перезагрузок. Turbo Streams для real-time обновлений аукционов. Stimulus controllers для: drag-and-drop в плейлистах, прогресс загрузки, обновления аукционов. Tailwind CSS. Responsive. Loading states определены для: upload, bid, schedule.  
**Performance**: ✅ PostgreSQL с eager loading (10 моделей, все FK проиндексированы). Solid Cache для fragment caching. Solid Queue для: обработки медиа, закрытия аукционов, уведомлений, запуска трансляций. Direct Upload обходит сервер приложения. Optimistic locking для аукционов. CHECK constraint для баланса.  
**Quality Gates**: ✅ RSpec (zero failures), RuboCop (zero offenses), Brakeman (zero warnings), bundler-audit (zero vulnerabilities), SimpleCov (>80%).

**No violations detected. Complexity Tracking section not needed.**

## Complexity Tracking

> No Constitution violations detected. All architectural decisions align with Constitution principles.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *None* | — | — |

## Generated Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Research | `specs/001-media-broadcast-platform/research.md` | 10 решений: архитектура, хранилище, аукционы, транзакции, устройства, таймзоны, уведомления, авторизация, фоновые задачи, кеширование |
| Data Model | `specs/001-media-broadcast-platform/data-model.md` | 11 моделей с полями, валидациями, ассоциациями, индексами, state machines |
| User API | `specs/001-media-broadcast-platform/contracts/user-api.md` | Эндпоинты для: медиа, плейлисты, устройства, аукционы, ставки, трансляции, баланс |
| Admin API | `specs/001-media-broadcast-platform/contracts/admin-api.md` | Эндпоинты для: устройства, группы, слоты, аукционы |
| Device API | `specs/001-media-broadcast-platform/contracts/device-api.md` | Эндпоинты для физических устройств: расписание, heartbeat, статус трансляции, WebSocket |
| Quickstart | `specs/001-media-broadcast-platform/quickstart.md` | Инструкции по настройке: gems, DB, Active Storage, MinIO, routes, TDD workflow |
| Agent Context | `.cursor/rules/specify-rules.mdc` | Обновлён для Cursor IDE с технологическим стеком |
