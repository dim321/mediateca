# Tasks: Multi-Tenant Media Broadcast Platform

**Input**: Design documents from `/specs/001-media-broadcast-platform/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: CONSTITUTION REQUIREMENT — TDD is mandatory. Tests MUST be written before implementation. Red-Green-Refactor cycle strictly enforced. Test coverage MUST exceed 80% for new code.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Rails 8 monolith**: `app/`, `spec/`, `config/`, `db/` at repository root
- Admin namespace: `app/controllers/admin/`, `app/views/admin/`
- Device API: `app/controllers/api/v1/device/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Инициализация Rails проекта, зависимости, конфигурация инструментов

- [x] T001 Create Rails 8 project with PostgreSQL 18 and Tailwind CSS (`rails new mediateca --database=postgresql --css=tailwind --skip-jbuilder --skip-test --asset-pipeline=propshaft`)
- [x] T002 Configure Gemfile with all dependencies per quickstart.md (devise, pundit, acts_as_tenant, streamio-ffmpeg, pagy, rspec-rails, factory_bot_rails, faker, shoulda-matchers, simplecov, capybara, brakeman, bundler-audit, rubocop-rails-omakase, database_cleaner-active_record)
- [x] T003 Run `bundle install` and verify all gems resolve
- [x] T004 [P] Initialize RSpec with `rails generate rspec:install`, configure `spec/spec_helper.rb` and `spec/rails_helper.rb` with FactoryBot, Shoulda Matchers, DatabaseCleaner, SimpleCov
- [x] T005 [P] Configure RuboCop with `rubocop-rails-omakase` in `.rubocop.yml`
- [x] T006 [P] Configure Active Storage with `rails active_storage:install`, setup `config/storage.yml` for local disk (development) and S3/MinIO
- [x] T007 [P] Configure Solid Queue for background jobs in `config/solid_queue.yml` with queues: default, media_processing, auctions, notifications, broadcasts
- [x] T008 Configure `config/database.yml` for PostgreSQL 18 and run `rails db:create`
- [x] T009 Configure `config/routes.rb` with full routing structure per contracts: user namespace, admin namespace, API v1 device namespace

**Checkpoint**: Project skeleton is ready, all tools configured, `bundle exec rspec` and `bundle exec rubocop` run successfully (zero specs, zero offenses)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Аутентификация, авторизация, базовая модель User — блокирует все user stories

**CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundation (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T010 [P] Write User model spec in `spec/models/user_spec.rb`: validations (email presence/uniqueness/format, first_name/last_name presence, role enum, balance numericality >= 0), associations (has_many media_files, playlists, bids, transactions, scheduled_broadcasts), enum :role
- [x] T011 [P] Write User factory in `spec/factories/users.rb` with traits :user, :admin, :with_balance
- [x] T012 [P] Write request specs for Devise authentication in `spec/requests/authentication_spec.rb`: sign_up, sign_in, sign_out, unauthorized access redirect
- [x] T013 [P] Write ApplicationPolicy spec in `spec/policies/application_policy_spec.rb`: base policy behavior, admin check, owner check

### Implementation for Foundation

- [x] T014 Generate and configure Devise with `rails generate devise:install` and `rails generate devise User` in `app/models/user.rb`
- [x] T015 Create User migration in `db/migrate/` adding: role (integer, default: 0), balance (decimal 12,2, default: 0), first_name (string), last_name (string), company_name (string), CHECK constraint `balance >= 0`
- [x] T016 Implement User model with validations, enums, associations in `app/models/user.rb`
- [x] T017 [P] Configure Devise views in `app/views/devise/` with Tailwind CSS styling
- [x] T018 [P] Initialize Pundit with `rails generate pundit:install`, create `app/policies/application_policy.rb` with base owner/admin checks
- [x] T019 Configure `app/controllers/application_controller.rb` with Devise authentication, Pundit authorization, acts_as_tenant current_tenant setup, error handling (Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound)
- [x] T020 [P] Create `app/controllers/admin/base_controller.rb` with admin-only authentication (`before_action :require_admin`)
- [x] T021 [P] Create shared layout `app/views/layouts/application.html.erb` with Tailwind CSS, navigation bar (user/admin), flash messages, Turbo integration
- [x] T022 Run `rails db:migrate` and verify all foundation tests pass (GREEN)

**Checkpoint**: Foundation ready — user authentication works, admin namespace protected, Pundit policies in place. User story implementation can now begin.

---

## Phase 3: User Story 1 — Media Upload and Playlist Creation (Priority: P1) MVP

**Goal**: Пользователь может загружать аудио/видео файлы в личную медиатеку и создавать из них плейлисты.

**Independent Test**: Загрузить медиафайл, увидеть его в медиатеке, создать плейлист, добавить файлы, убедиться в корректном порядке и длительности.

**FR**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-024

### Tests for User Story 1 (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T023 [P] [US1] Write MediaFile model spec in `spec/models/media_file_spec.rb`: validations (title presence, media_type enum, format inclusion, file_size <= 100MB, processing_status enum), associations (belongs_to user, has_one_attached file, has_many playlist_items), scopes
- [x] T024 [P] [US1] Write Playlist model spec in `spec/models/playlist_spec.rb`: validations (name presence, name uniqueness scoped to user_id, total_duration >= 0), associations (belongs_to user, has_many playlist_items ordered by position, has_many media_files through playlist_items)
- [x] T025 [P] [US1] Write PlaylistItem model spec in `spec/models/playlist_item_spec.rb`: validations (position presence/numericality, uniqueness of playlist_id+position, uniqueness of playlist_id+media_file_id), associations (belongs_to playlist with touch, belongs_to media_file)
- [x] T026 [P] [US1] Write MediaFile factory in `spec/factories/media_files.rb` with traits :audio, :video, :pending, :ready, :failed, :with_file
- [x] T027 [P] [US1] Write Playlist and PlaylistItem factories in `spec/factories/playlists.rb` and `spec/factories/playlist_items.rb`
- [x] T028 [P] [US1] Write Media::UploadService spec in `spec/services/media/upload_service_spec.rb`: successful upload, format validation, size validation, processing_status set to pending, MediaProcessingJob enqueued
- [x] T029 [P] [US1] Write Media::ValidationService spec in `spec/services/media/validation_service_spec.rb`: valid formats (mp4, avi, mov, mp3, aac, wav), invalid formats, size limits, corrupted file detection
- [x] T030 [P] [US1] Write MediaProcessingJob spec in `spec/jobs/media_processing_job_spec.rb`: extracts duration via ffprobe, updates processing_status to ready/failed
- [x] T031 [P] [US1] Write MediaFilePolicy spec in `spec/policies/media_file_policy_spec.rb`: owner can CRUD, non-owner cannot access, admin cannot access other users' files
- [x] T032 [P] [US1] Write PlaylistPolicy spec in `spec/policies/playlist_policy_spec.rb`: owner can CRUD, non-owner cannot access
- [x] T033 [P] [US1] Write request specs for MediaFiles in `spec/requests/media_files_spec.rb`: GET index (with media_type filter, pagination), POST create (valid/invalid), GET show (owner only), DELETE destroy (owner only, restrict if in playlist)
- [x] T034 [P] [US1] Write request specs for Playlists in `spec/requests/playlists_spec.rb`: CRUD operations, reorder action, total_duration calculation
- [x] T035 [P] [US1] Write request specs for PlaylistItems in `spec/requests/playlist_items_spec.rb`: add item, update position, remove item, duration recalculation
- [x] T036 [US1] Write system spec for media upload flow in `spec/system/media_upload_spec.rb`: user signs in, uploads file, sees it in library, creates playlist, adds files, reorders, verifies duration

### Implementation for User Story 1

- [x] T037 [P] [US1] Create MediaFile migration in `db/migrate/` with fields per data-model.md: user_id, title, media_type, format, duration, file_size, processing_status; indexes on (user_id), (user_id, media_type), (user_id, created_at)
- [x] T038 [P] [US1] Create Playlist migration in `db/migrate/` with fields: user_id, name, description, total_duration, items_count; index on (user_id)
- [x] T039 [P] [US1] Create PlaylistItem migration in `db/migrate/` with fields: playlist_id, media_file_id, position; unique indexes on (playlist_id, position) and (playlist_id, media_file_id)
- [x] T040 [US1] Run `rails db:migrate` for US1 models
- [x] T041 [P] [US1] Implement MediaFile model in `app/models/media_file.rb`: validations, enums (media_type, processing_status), has_one_attached :file, format/size validation, scopes (:audio, :video, :ready)
- [x] T042 [P] [US1] Implement Playlist model in `app/models/playlist.rb`: validations, associations with ordered playlist_items, callback for total_duration recalculation, counter_cache for items_count
- [x] T043 [P] [US1] Implement PlaylistItem model in `app/models/playlist_item.rb`: validations, belongs_to with touch, position management
- [x] T044 [US1] Implement Media::ValidationService in `app/services/media/validation_service.rb`: validate format, size (<=100MB), content type matching, corrupted file header check
- [x] T045 [US1] Implement Media::UploadService in `app/services/media/upload_service.rb`: validate via ValidationService, create MediaFile record, attach file, enqueue MediaProcessingJob
- [x] T046 [US1] Implement MediaProcessingJob in `app/jobs/media_processing_job.rb`: download file, extract metadata (duration, format) via streamio-ffmpeg, update MediaFile processing_status (ready/failed)
- [x] T047 [P] [US1] Implement MediaFilePolicy in `app/policies/media_file_policy.rb`: owner-only access per FR-001
- [x] T048 [P] [US1] Implement PlaylistPolicy in `app/policies/playlist_policy.rb`: owner-only access per FR-001
- [x] T049 [US1] Implement MediaFilesController in `app/controllers/media_files_controller.rb`: index (with filtering by media_type, pagination via Pagy), show, create (via UploadService), destroy (restrict if in playlist)
- [x] T050 [US1] Implement PlaylistsController in `app/controllers/playlists_controller.rb`: CRUD, reorder action (accepts item_ids array, updates positions), show with eager-loaded items
- [x] T051 [US1] Implement PlaylistItemsController in `app/controllers/playlist_items_controller.rb`: create (add media to playlist), update (change position), destroy (remove from playlist)
- [x] T052 [P] [US1] Create media_files views in `app/views/media_files/`: index.html.erb (grid/list with Turbo Frames, filter by type), show.html.erb (file details, preview), _form.html.erb (upload with Direct Upload), _media_file.html.erb (partial for list item)
- [x] T053 [P] [US1] Create playlists views in `app/views/playlists/`: index.html.erb (list with duration), show.html.erb (items with drag-and-drop reorder), new/edit forms, _playlist.html.erb (partial)
- [x] T054 [US1] Implement Stimulus upload_controller in `app/javascript/controllers/upload_controller.js`: Direct Upload progress bar, file type/size client-side validation, upload status display
- [x] T055 [US1] Implement Stimulus playlist_sort_controller in `app/javascript/controllers/playlist_sort_controller.js`: drag-and-drop reordering via Sortable, PATCH to reorder endpoint
- [x] T056 [US1] Run full US1 test suite and verify all tests pass (GREEN), check coverage

**Checkpoint**: User Story 1 fully functional — users can upload media files, view library, create playlists, add/reorder items, see total duration. Independently testable.

---

## Phase 4: User Story 2 — Device Management and Basic Scheduling (Priority: P2)

**Goal**: Администратор может регистрировать устройства трансляции и настраивать расписание 30-минутных слотов.

**Independent Test**: Админ добавляет устройство с адресом, видит его в списке, генерирует слоты на дату, устанавливает цены.

**FR**: FR-007, FR-008, FR-009, FR-010, FR-026

### Tests for User Story 2 (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T057 [P] [US2] Write BroadcastDevice model spec in `spec/models/broadcast_device_spec.rb`: validations (name/city/address presence, time_zone inclusion, api_token uniqueness), associations (has_many time_slots, device_group_memberships), auto-generation of api_token on create, status enum
- [x] T058 [P] [US2] Write TimeSlot model spec in `spec/models/time_slot_spec.rb`: validations (start_time/end_time presence, end_time > start_time, 30-min duration, starting_price >= 0, uniqueness of device+start_time), associations (belongs_to broadcast_device, has_one auction, has_one scheduled_broadcast), slot_status enum, state transitions
- [x] T059 [P] [US2] Write BroadcastDevice and TimeSlot factories in `spec/factories/broadcast_devices.rb` and `spec/factories/time_slots.rb` with traits :online, :offline, :available, :auction_active, :sold
- [x] T060 [P] [US2] Write request specs for Admin::DevicesController in `spec/requests/admin/devices_spec.rb`: CRUD, admin-only access, validation errors for missing fields, filter by city/status
- [x] T061 [P] [US2] Write request specs for Admin::TimeSlotsController in `spec/requests/admin/time_slots_spec.rb`: generate slots for date (48 slots), update starting_price, duplicate date rejection, schedule display with timezone
- [x] T062 [US2] Write system spec for device management in `spec/system/admin/device_management_spec.rb`: admin signs in, adds device, views list, generates schedule, sets prices

### Implementation for User Story 2

- [x] T063 [P] [US2] Create BroadcastDevice migration in `db/migrate/` with fields per data-model.md: name, city, address, time_zone, status, api_token, last_heartbeat_at, description; indexes on (city), (status), (api_token) UNIQUE
- [x] T064 [P] [US2] Create TimeSlot migration in `db/migrate/` with fields: broadcast_device_id, start_time, end_time, starting_price, slot_status; indexes on (broadcast_device_id, start_time) UNIQUE, (broadcast_device_id, slot_status), (start_time)
- [x] T065 [US2] Run `rails db:migrate` for US2 models
- [x] T066 [P] [US2] Implement BroadcastDevice model in `app/models/broadcast_device.rb`: validations, enum :status, api_token auto-generation (SecureRandom.hex), time_zone validation against ActiveSupport::TimeZone
- [x] T067 [P] [US2] Implement TimeSlot model in `app/models/time_slot.rb`: validations (30-min duration, no overlap), enum :slot_status, scopes (:available, :for_date), time zone display helpers
- [x] T068 [US2] Implement Admin::DevicesController in `app/controllers/admin/devices_controller.rb`: CRUD with filtering (city, status, group), pagination via Pagy, api_token shown once on create
- [x] T069 [US2] Implement Admin::TimeSlotsController in `app/controllers/admin/time_slots_controller.rb`: index (schedule for date), generate action (create 48 slots for date in device timezone, converted to UTC), update (starting_price)
- [x] T070 [P] [US2] Create admin device views in `app/views/admin/devices/`: index.html.erb (list with filters), show.html.erb (details + schedule), new/edit forms, _device.html.erb
- [x] T071 [P] [US2] Create admin time_slots views in `app/views/admin/time_slots/`: index.html.erb (daily schedule grid), _time_slot.html.erb (slot with price edit)
- [x] T072 [US2] Implement Stimulus schedule_controller in `app/javascript/controllers/schedule_controller.js`: date picker for schedule view, inline price editing via Turbo Frames
- [x] T073 [US2] Run full US2 test suite and verify all tests pass (GREEN)

**Checkpoint**: User Story 2 fully functional — admins can register devices, generate 30-min slot schedules, set prices. Independently testable.

---

## Phase 5: User Story 3 — Playlist Broadcasting to Devices (Priority: P3)

**Goal**: Пользователь может выбрать устройство, временной слот и запланировать трансляцию своего плейлиста.

**Independent Test**: Пользователь видит устройства, открывает расписание, выбирает слот, назначает плейлист, видит запланированную трансляцию.

**FR**: FR-011, FR-012, FR-013

**Dependencies**: Requires US1 (playlists) and US2 (devices/time slots) to be complete.

### Tests for User Story 3 (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T074 [P] [US3] Write ScheduledBroadcast model spec in `spec/models/scheduled_broadcast_spec.rb`: validations (time_slot_id uniqueness, playlist duration <= slot duration), associations (belongs_to user/playlist/time_slot/auction), broadcast_status enum, state transitions (scheduled→playing→completed/failed)
- [x] T075 [P] [US3] Write ScheduledBroadcast factory in `spec/factories/scheduled_broadcasts.rb` with traits :scheduled, :playing, :completed, :failed
- [x] T076 [P] [US3] Write Broadcasts::ScheduleService spec in `spec/services/broadcasts/schedule_service_spec.rb`: successful scheduling, duration validation (FR-013), slot availability check, slot status update to :sold
- [x] T077 [P] [US3] Write BroadcastStartJob spec in `spec/jobs/broadcast_start_job_spec.rb`: updates broadcast_status to :playing, handles offline device
- [x] T078 [P] [US3] Write BroadcastPolicy spec in `spec/policies/broadcast_policy_spec.rb`: owner can view/create, non-owner cannot access
- [x] T079 [P] [US3] Write request specs for DevicesController (user-facing) in `spec/requests/devices_spec.rb`: GET index (list devices with city filter), GET schedule (device schedule with available slots)
- [x] T080 [P] [US3] Write request specs for BroadcastsController in `spec/requests/broadcasts_spec.rb`: GET index (user's broadcasts with status filter), POST create (schedule playlist, duration validation, slot availability)
- [x] T081 [US3] Write system spec for broadcast scheduling in `spec/system/broadcast_scheduling_spec.rb`: user views devices, selects slot, schedules playlist, sees broadcast in list

### Implementation for User Story 3

- [x] T082 [US3] Create ScheduledBroadcast migration in `db/migrate/` with fields per data-model.md: user_id, playlist_id, time_slot_id, auction_id, broadcast_status, started_at, completed_at; indexes on (time_slot_id) UNIQUE, (user_id, broadcast_status), (broadcast_status, time_slot_id)
- [x] T083 [US3] Run `rails db:migrate` for US3 model
- [x] T084 [US3] Implement ScheduledBroadcast model in `app/models/scheduled_broadcast.rb`: validations, enum :broadcast_status, playlist duration validation (FR-013), associations
- [x] T085 [US3] Implement Broadcasts::ScheduleService in `app/services/broadcasts/schedule_service.rb`: validate slot available, validate playlist duration <= 30 min (FR-013), create ScheduledBroadcast, update TimeSlot status to :sold
- [x] T086 [US3] Implement BroadcastStartJob in `app/jobs/broadcast_start_job.rb`: triggered by Solid Queue at slot start_time, update broadcast_status to :playing, handle device offline
- [x] T087 [US3] Implement BroadcastPolicy in `app/policies/broadcast_policy.rb`: owner-only access
- [x] T088 [US3] Implement DevicesController (user-facing) in `app/controllers/devices_controller.rb`: index (list available devices, filter by city), schedule action (show device schedule for date with slot statuses)
- [x] T089 [US3] Implement BroadcastsController in `app/controllers/broadcasts_controller.rb`: index (user's broadcasts, filter by status, pagination), create (via ScheduleService)
- [x] T090 [P] [US3] Create user-facing device views in `app/views/devices/`: index.html.erb (device cards with city filter), schedule.html.erb (daily schedule with available/sold slots)
- [x] T091 [P] [US3] Create broadcast views in `app/views/broadcasts/`: index.html.erb (broadcast list with status badges), _broadcast.html.erb (partial with device/slot/playlist info)
- [x] T092 [US3] Run full US3 test suite and verify all tests pass (GREEN)

**Checkpoint**: User Story 3 fully functional — users can browse devices, view schedules, schedule playlists for broadcast. Independently testable (with US1+US2 data).

---

## Phase 6: User Story 4 — Device Grouping (Priority: P4)

**Goal**: Администратор может объединять устройства в группы для упрощения управления.

**Independent Test**: Админ создаёт группу, добавляет устройства, фильтрует по группе, удаляет группу — устройства остаются.

**FR**: FR-014, FR-015

### Tests for User Story 4 (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T093 [P] [US4] Write DeviceGroup model spec in `spec/models/device_group_spec.rb`: validations (name presence/uniqueness), associations (has_many device_group_memberships, broadcast_devices through), counter_cache :devices_count
- [x] T094 [P] [US4] Write DeviceGroupMembership model spec in `spec/models/device_group_membership_spec.rb`: validations (uniqueness of device+group), associations (belongs_to broadcast_device, belongs_to device_group with counter_cache)
- [x] T095 [P] [US4] Write DeviceGroup and DeviceGroupMembership factories in `spec/factories/device_groups.rb` and `spec/factories/device_group_memberships.rb`
- [x] T096 [P] [US4] Write request specs for Admin::DeviceGroupsController in `spec/requests/admin/device_groups_spec.rb`: CRUD, add_devices, remove_device, filter devices by group (FR-015), delete group preserves devices
- [x] T097 [US4] Write system spec for device grouping in `spec/system/admin/device_grouping_spec.rb`: admin creates group, adds devices, filters by group, removes device from group, deletes group

### Implementation for User Story 4

- [x] T098 [P] [US4] Create DeviceGroup migration in `db/migrate/` with fields: name, description, devices_count (default 0)
- [x] T099 [P] [US4] Create DeviceGroupMembership migration in `db/migrate/` with fields: broadcast_device_id, device_group_id; unique index on (broadcast_device_id, device_group_id)
- [x] T100 [US4] Run `rails db:migrate` for US4 models
- [x] T101 [P] [US4] Implement DeviceGroup model in `app/models/device_group.rb`: validations, associations through DeviceGroupMembership
- [x] T102 [P] [US4] Implement DeviceGroupMembership model in `app/models/device_group_membership.rb`: validations, counter_cache on device_group
- [x] T103 [US4] Add device_group_memberships association to BroadcastDevice model in `app/models/broadcast_device.rb`
- [x] T104 [US4] Implement Admin::DeviceGroupsController in `app/controllers/admin/device_groups_controller.rb`: CRUD, add_devices (bulk add), remove_device, filter by group_id
- [x] T105 [US4] Update Admin::DevicesController in `app/controllers/admin/devices_controller.rb`: add group_id filter to index action (FR-015)
- [x] T106 [P] [US4] Create admin device_groups views in `app/views/admin/device_groups/`: index.html.erb (groups with device count), show.html.erb (group with device list, add/remove), new/edit forms
- [x] T107 [US4] Update user-facing DevicesController index in `app/controllers/devices_controller.rb`: add group_id filter parameter
- [x] T108 [US4] Run full US4 test suite and verify all tests pass (GREEN)

**Checkpoint**: User Story 4 fully functional — admins can manage device groups, filter devices by group. Independently testable.

---

## Phase 7: User Story 5 — Auction-Based Slot Purchasing (Priority: P5)

**Goal**: Пользователи участвуют в аукционах за временные слоты, побеждает наивысшая ставка.

**Independent Test**: Пользователь видит аукцион, делает ставку, другой пользователь перебивает, аукцион закрывается, победитель получает слот.

**FR**: FR-016, FR-017, FR-018, FR-025

**Dependencies**: Requires US2 (time slots) and US6 (balance) for full flow, but can work with balance validation stubbed.

### Tests for User Story 5 (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T109 [P] [US5] Write Auction model spec in `spec/models/auction_spec.rb`: validations (time_slot_id uniqueness, starting_price > 0, closes_at before slot start_time), associations (belongs_to time_slot, has_many bids, belongs_to highest_bidder optional), enum :auction_status, lock_version for optimistic locking
- [x] T110 [P] [US5] Write Bid model spec in `spec/models/bid_spec.rb`: validations (amount > 0, amount > current_highest_bid), associations (belongs_to auction, belongs_to user), ordering by created_at for FR-025 tie-breaking
- [x] T111 [P] [US5] Write Auction and Bid factories in `spec/factories/auctions.rb` and `spec/factories/bids.rb` with traits :open, :closed, :cancelled, :with_bids
- [x] T112 [P] [US5] Write Auctions::BidService spec in `spec/services/auctions/bid_service_spec.rb`: successful bid, bid too low, auction closed, insufficient balance (FR-022), optimistic lock conflict with retry, concurrent bids tie-breaking by created_at (FR-025)
- [x] T113 [P] [US5] Write Auctions::CloseAuctionService spec in `spec/services/auctions/close_auction_service_spec.rb`: winner determination, balance deduction, ScheduledBroadcast creation, no-bid auction handling, notification to winner
- [x] T114 [P] [US5] Write Auctions::NotificationService spec in `spec/services/auctions/notification_service_spec.rb`: outbid notification via Turbo Stream, auction won notification, email delivery
- [x] T115 [P] [US5] Write AuctionCloseJob spec in `spec/jobs/auction_close_job_spec.rb`: calls CloseAuctionService, handles already-closed auction
- [x] T116 [P] [US5] Write OutbidNotificationJob spec in `spec/jobs/outbid_notification_job_spec.rb`: sends Turbo Stream broadcast, enqueues email
- [x] T117 [P] [US5] Write AuctionPolicy spec in `spec/policies/auction_policy_spec.rb`: any user can view, any user can bid on open auction
- [x] T118 [P] [US5] Write request specs for AuctionsController in `spec/requests/auctions_spec.rb`: GET index (with device_id/status filters), GET show (with bids and my_bids)
- [x] T119 [P] [US5] Write request specs for BidsController in `spec/requests/bids_spec.rb`: POST create (valid bid, bid too low, insufficient balance, auction closed, optimistic lock conflict 409)
- [x] T120 [US5] Write system spec for auction flow in `spec/system/auction_flow_spec.rb`: user views auctions, places bid, sees confirmation, another user outbids, auction closes, winner notified

### Implementation for User Story 5

- [x] T121 [P] [US5] Create Auction migration in `db/migrate/` with fields per data-model.md: time_slot_id, starting_price, current_highest_bid, highest_bidder_id, closes_at, auction_status, lock_version; indexes on (time_slot_id) UNIQUE, (auction_status, closes_at), (highest_bidder_id)
- [x] T122 [P] [US5] Create Bid migration in `db/migrate/` with fields: auction_id, user_id, amount; indexes on (auction_id, amount DESC), (auction_id, created_at), (user_id)
- [x] T123 [US5] Run `rails db:migrate` for US5 models
- [x] T124 [P] [US5] Implement Auction model in `app/models/auction.rb`: validations, enum :auction_status, optimistic locking (lock_version), associations, scope :open, :closing_soon
- [x] T125 [P] [US5] Implement Bid model in `app/models/bid.rb`: validations (amount > current_highest_bid), associations, default scope by created_at for FR-025
- [x] T126 [US5] Implement Auctions::BidService in `app/services/auctions/bid_service.rb`: validate auction open, validate amount > current_highest_bid, validate user balance (FR-022), update auction with optimistic lock, create Bid record, enqueue OutbidNotificationJob, retry on StaleObjectError
- [x] T127 [US5] Implement Auctions::CloseAuctionService in `app/services/auctions/close_auction_service.rb`: determine winner (highest bid, earliest on tie — FR-025), deduct balance via Billing::DeductionService, create ScheduledBroadcast, update TimeSlot status, update Auction status to :closed, notify winner
- [x] T128 [US5] Implement Auctions::NotificationService in `app/services/auctions/notification_service.rb`: send Turbo Stream broadcast to outbid user, send email via Action Mailer
- [x] T129 [P] [US5] Implement AuctionCloseJob in `app/jobs/auction_close_job.rb`: call CloseAuctionService, idempotent (skip if already closed)
- [x] T130 [P] [US5] Implement OutbidNotificationJob in `app/jobs/outbid_notification_job.rb`: call NotificationService
- [x] T131 [US5] Implement AuctionPolicy in `app/policies/auction_policy.rb`: index/show for all authenticated users, bid only on open auctions
- [x] T132 [US5] Implement AuctionsController in `app/controllers/auctions_controller.rb`: index (filter by device_id, status, pagination), show (with bids, my_bids, eager loading)
- [x] T133 [US5] Implement BidsController in `app/controllers/bids_controller.rb`: create (via BidService, handle StaleObjectError as 409 Conflict)
- [x] T134 [US5] Add create_auction action to Admin::TimeSlotsController in `app/controllers/admin/time_slots_controller.rb`: create Auction for slot with closes_at, enqueue AuctionCloseJob at closes_at
- [x] T135 [P] [US5] Create auction views in `app/views/auctions/`: index.html.erb (auction list with countdown timers), show.html.erb (bid history, current price, bid form via Turbo Frame)
- [x] T136 [P] [US5] Create bid form partial in `app/views/bids/`: _form.html.erb (amount input, balance display, Turbo Stream target for errors)
- [x] T137 [US5] Implement Stimulus auction_controller in `app/javascript/controllers/auction_controller.js`: countdown timer, real-time bid updates via Turbo Streams, balance check before submit
- [x] T138 [P] [US5] Create OutbidMailer in `app/mailers/outbid_mailer.rb` with outbid_notification and auction_won_notification templates
- [x] T139 [US5] Configure Solid Queue recurring task for auction close job polling in `config/recurring.yml`: check for auctions past closes_at every 10 seconds
- [x] T140 [US5] Run full US5 test suite and verify all tests pass (GREEN)

**Checkpoint**: User Story 5 fully functional — users can view auctions, place bids, receive outbid notifications, winners get slots. Independently testable.

---

## Phase 8: User Story 6 — Account Balance and Payment Processing (Priority: P6)

**Goal**: Пользователь может пополнять баланс, средства автоматически списываются при выигрыше аукциона.

**Independent Test**: Пользователь пополняет баланс, видит его, выигрывает аукцион — баланс уменьшается, видит историю транзакций.

**FR**: FR-019, FR-020, FR-021, FR-022, FR-023

### Tests for User Story 6 (MANDATORY — TDD Required)

> **CONSTITUTION REQUIREMENT: Tests MUST be written FIRST, MUST FAIL before implementation.**

- [x] T141 [P] [US6] Write Transaction model spec in `spec/models/transaction_spec.rb`: validations (amount != 0, transaction_type presence, description presence), associations (belongs_to user, belongs_to reference polymorphic optional), immutability (cannot update/destroy), enum :transaction_type
- [x] T142 [P] [US6] Write Transaction factory in `spec/factories/transactions.rb` with traits :deposit, :deduction, :for_auction, :for_broadcast
- [x] T143 [P] [US6] Write Billing::DepositService spec in `spec/services/billing/deposit_service_spec.rb`: successful deposit, amount validation (> 0), Transaction created, User balance updated, atomicity
- [x] T144 [P] [US6] Write Billing::DeductionService spec in `spec/services/billing/deduction_service_spec.rb`: successful deduction, insufficient balance rejection (FR-022), Transaction created, User balance updated, pessimistic locking (SELECT FOR UPDATE), atomicity, CHECK constraint prevents negative balance
- [x] T145 [P] [US6] Write Billing::BalanceCheckService spec in `spec/services/billing/balance_check_service_spec.rb`: sufficient balance returns true, insufficient returns false with details
- [x] T146 [P] [US6] Write request specs for BalancesController in `spec/requests/balances_spec.rb`: GET show (current balance + transaction history with pagination), POST deposit (valid/invalid amount)
- [x] T147 [US6] Write system spec for balance management in `spec/system/balance_management_spec.rb`: user views balance, deposits funds, sees updated balance, views transaction history

### Implementation for User Story 6

- [x] T148 [US6] Create Transaction migration in `db/migrate/` with fields per data-model.md: user_id, amount, transaction_type, description, reference_type, reference_id; indexes on (user_id, created_at DESC), (reference_type, reference_id)
- [x] T149 [US6] Run `rails db:migrate` for US6 model
- [x] T150 [US6] Implement Transaction model in `app/models/transaction.rb`: validations, enum :transaction_type, polymorphic reference, immutability (raise on update/destroy), belongs_to user
- [x] T151 [US6] Implement Billing::DepositService in `app/services/billing/deposit_service.rb`: validate amount > 0, create Transaction (type: deposit), update User#balance in DB transaction
- [x] T152 [US6] Implement Billing::DeductionService in `app/services/billing/deduction_service.rb`: pessimistic lock User (SELECT FOR UPDATE), check balance >= amount, create Transaction (type: deduction, negative amount), update User#balance, raise InsufficientBalanceError if failed
- [x] T153 [US6] Implement Billing::BalanceCheckService in `app/services/billing/balance_check_service.rb`: check user.balance >= required_amount, return result with current_balance and deficit
- [x] T154 [US6] Implement BalancesController in `app/controllers/balances_controller.rb`: show (current balance + transactions paginated via Pagy), deposit (via DepositService)
- [x] T155 [P] [US6] Create balance views in `app/views/balances/`: show.html.erb (current balance card, deposit form, transaction history table with pagination)
- [x] T156 [US6] Integrate Billing services with Auctions::BidService — add balance check before bid in `app/services/auctions/bid_service.rb`
- [x] T157 [US6] Integrate Billing::DeductionService with Auctions::CloseAuctionService — deduct winner's balance in `app/services/auctions/close_auction_service.rb`
- [x] T158 [US6] Run full US6 test suite and verify all tests pass (GREEN)

**Checkpoint**: User Story 6 fully functional — users can deposit funds, view balance and transaction history, funds deducted on auction win. Full auction-to-payment flow works.

---

## Phase 9: Device Communication API

**Purpose**: REST API и WebSocket для физических устройств трансляции (ТВ). Не привязан к конкретной user story, обеспечивает инфраструктуру трансляций.

### Tests (MANDATORY — TDD Required)

- [x] T159 [P] Write request specs for Device API in `spec/requests/api/v1/device_spec.rb`: GET schedule (valid token, invalid token, schedule with broadcasts), POST heartbeat (status update, last_heartbeat_at), POST broadcast_status (playing/completed/failed)
- [x] T160 [P] Write Broadcasts::PlaybackService spec in `spec/services/broadcasts/playback_service_spec.rb`: update broadcast status, handle completion, handle failure
- [x] T161 [P] Write DeviceScheduleChannel spec in `spec/channels/device_schedule_channel_spec.rb`: subscribe with valid token, reject invalid token, receive schedule updates

### Implementation

- [x] T162 Implement Api::V1::Device::BaseController in `app/controllers/api/v1/device/base_controller.rb`: Bearer token authentication, find device by token, JSON-only responses
- [x] T163 Implement Api::V1::Device::SchedulesController in `app/controllers/api/v1/device/schedules_controller.rb`: GET schedule (day's time slots with broadcasts, playlists, media file download URLs)
- [x] T164 Implement Api::V1::Device::HeartbeatsController in `app/controllers/api/v1/device/heartbeats_controller.rb`: POST heartbeat (update device status and last_heartbeat_at)
- [x] T165 Implement Api::V1::Device::BroadcastStatusesController in `app/controllers/api/v1/device/broadcast_statuses_controller.rb`: POST broadcast_status (update via PlaybackService)
- [x] T166 Implement Broadcasts::PlaybackService in `app/services/broadcasts/playback_service.rb`: update ScheduledBroadcast status (playing/completed/failed), update TimeSlot status
- [x] T167 Implement DeviceScheduleChannel in `app/channels/device_schedule_channel.rb`: subscribe with device token, broadcast schedule updates on ScheduledBroadcast create/cancel
- [x] T168 Run full Device API test suite and verify all tests pass (GREEN)

**Checkpoint**: Device API functional — physical devices can fetch schedule, send heartbeats, report broadcast status, receive real-time updates.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Качество, производительность, безопасность — затрагивает все user stories

- [x] T169 [P] Add eager loading to all controllers to prevent N+1 queries: MediaFilesController (includes :user), PlaylistsController (includes playlist_items: :media_file), DevicesController (includes :device_groups), AuctionsController (includes :bids, time_slot: :broadcast_device)
- [x] T170 [P] Implement fragment caching in views: media_files index, playlists index, devices index, schedule view — with `cache_key_with_version` and Russian Doll pattern
- [x] T171 [P] Add database indexes verification — run `rails db:migrate:status` and verify all indexes from data-model.md are present
- [x] T172 [P] Run `bundle exec rubocop --autocorrect-all` and fix all remaining offenses to reach zero offenses
- [x] T173 [P] Run `bundle exec brakeman --no-pager` and fix all security warnings
- [x] T174 [P] Run `bundle exec bundler-audit check --update` and resolve all vulnerable dependencies
- [x] T175 [P] Run `bundle exec rspec` with SimpleCov and verify coverage >80% for all new code. Add missing specs to reach threshold
- [x] T176 [P] Create seed data in `db/seeds.rb`: admin user, sample users with media files and playlists, sample devices with groups and schedules, sample auctions with bids
- [x] T177 Verify all success criteria from spec.md: SC-001 through SC-012 — document results
- [x] T178 Final full test suite run: `bundle exec rspec` — all green, coverage >80%, zero RuboCop offenses, zero Brakeman warnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundation — no cross-story dependencies
- **US2 (Phase 4)**: Depends on Foundation — no cross-story dependencies, **can run in parallel with US1**
- **US3 (Phase 5)**: Depends on US1 (playlists) + US2 (devices/time slots)
- **US4 (Phase 6)**: Depends on US2 (devices) — **can run in parallel with US1, US3**
- **US5 (Phase 7)**: Depends on US2 (time slots) + US6 (balance) for full flow
- **US6 (Phase 8)**: Depends on Foundation — **can run in parallel with US1, US2**
- **Device API (Phase 9)**: Depends on US2 (devices) + US3 (broadcasts)
- **Polish (Phase 10)**: Depends on all desired stories being complete

### User Story Dependencies

```
Foundation ──┬── US1 (P1) ──────────────┬── US3 (P3) ──┬── Device API
             │                          │              │
             ├── US2 (P2) ──────────────┘              ├── Polish
             │       │                                 │
             │       ├── US4 (P4) ─────────────────────┘
             │       │
             ├── US6 (P6) ── US5 (P5) ─────────────────┘
             │
             └── (parallel opportunities)
```

### Within Each User Story

1. Tests MUST be written and FAIL before implementation (RED)
2. Models → Services → Jobs → Policies (in parallel where marked [P])
3. Controllers → Views → Stimulus (sequential)
4. Run all story tests — must pass (GREEN)
5. Refactor if needed
6. Story complete before moving to next priority

### Parallel Opportunities

- **After Foundation**: US1, US2, US4, US6 can all start in parallel
- **Within each story**: All test tasks marked [P] can run in parallel
- **Within each story**: All model tasks marked [P] can run in parallel
- **Cross-story**: US1 and US2 are fully independent — different models, controllers, views

---

## Parallel Example: User Story 1

```text
# Batch 1: All test specs in parallel
T023 [P] [US1] MediaFile model spec
T024 [P] [US1] Playlist model spec
T025 [P] [US1] PlaylistItem model spec
T026 [P] [US1] MediaFile factory
T027 [P] [US1] Playlist/PlaylistItem factories
T028 [P] [US1] UploadService spec
T029 [P] [US1] ValidationService spec
T030 [P] [US1] MediaProcessingJob spec
T031 [P] [US1] MediaFilePolicy spec
T032 [P] [US1] PlaylistPolicy spec
T033 [P] [US1] MediaFiles request spec
T034 [P] [US1] Playlists request spec
T035 [P] [US1] PlaylistItems request spec

# Batch 2: Migrations in parallel
T037 [P] [US1] MediaFile migration
T038 [P] [US1] Playlist migration
T039 [P] [US1] PlaylistItem migration
T040       Run db:migrate

# Batch 3: Models in parallel
T041 [P] [US1] MediaFile model
T042 [P] [US1] Playlist model
T043 [P] [US1] PlaylistItem model

# Batch 4: Services (sequential due to dependency)
T044 ValidationService → T045 UploadService → T046 MediaProcessingJob

# Batch 5: Policies in parallel
T047 [P] [US1] MediaFilePolicy
T048 [P] [US1] PlaylistPolicy

# Batch 6: Controllers (sequential)
T049 MediaFilesController → T050 PlaylistsController → T051 PlaylistItemsController

# Batch 7: Views and Stimulus in parallel
T052 [P] [US1] media_files views
T053 [P] [US1] playlists views
T054 upload_controller.js → T055 playlist_sort_controller.js

# Batch 8: System test + verification
T036 System spec → T056 Full test suite run
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test US1 independently
5. Deploy/demo if ready — users can upload media and create playlists

### Incremental Delivery

1. Setup + Foundation → Foundation ready
2. Add US1 → Test → Deploy/Demo (**MVP!** — media upload + playlists)
3. Add US2 → Test → Deploy/Demo (admin can setup devices)
4. Add US3 → Test → Deploy/Demo (users can schedule broadcasts)
5. Add US4 → Test → Deploy/Demo (device grouping)
6. Add US6 → Test → Deploy/Demo (balance management)
7. Add US5 → Test → Deploy/Demo (auctions — full platform!)
8. Add Device API → Test → Deploy (physical device support)
9. Polish → Final release

### Parallel Team Strategy

With 2-3 developers after Foundation:

- **Developer A**: US1 (media/playlists) → US3 (broadcasts)
- **Developer B**: US2 (devices/schedule) → US4 (groups) → Device API
- **Developer C**: US6 (balance) → US5 (auctions)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- TDD is mandatory — tests MUST fail before implementation (RED → GREEN → Refactor)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution compliance: RuboCop zero offenses, Brakeman zero warnings, SimpleCov >80%
