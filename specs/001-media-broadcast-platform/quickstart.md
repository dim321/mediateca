# Quickstart: Multi-Tenant Media Broadcast Platform

**Date**: 2026-02-12  
**Feature**: [spec.md](spec.md)

## Prerequisites

- **Ruby** 3.4.7
- **PostgreSQL** 18
- **Node.js** 20+ (для asset pipeline)
- **FFmpeg** (для обработки медиафайлов — `ffprobe` используется для извлечения метаданных)
- **MinIO** или S3-совместимое хранилище (для медиафайлов в development)

## Initial Setup

### 1. Создание Rails приложения

```bash
rails new mediateca \
  --database=postgresql \
  --css=tailwind \
  --skip-jbuilder \
  --skip-test \
  --asset-pipeline=propshaft

cd mediateca
```

### 2. Настройка Gemfile

Добавить ключевые зависимости:

```ruby
# Gemfile

# === Authentication & Authorization ===
gem "devise"                    # Аутентификация пользователей
gem "pundit"                    # Авторизация через policy objects

# === Background Jobs ===
# Solid Queue включён в Rails 8 по умолчанию

# === Media Processing ===
gem "streamio-ffmpeg"           # FFmpeg wrapper для Ruby (метаданные медиа)
gem "image_processing"          # Active Storage variants (если потребуются превью)

# === Multi-tenancy ===
gem "acts_as_tenant"            # Tenant scoping

# === UI ===
gem "pagy"                      # Пагинация (быстрее, чем Kaminari/WillPaginate)

group :development, :test do
  gem "rspec-rails"             # Тестовый фреймворк
  gem "factory_bot_rails"       # Фабрики тестовых данных
  gem "faker"                   # Генерация тестовых данных
  gem "shoulda-matchers"        # Матчеры для моделей
  gem "rubocop-rails-omakase"   # Rails 8 RuboCop config
  gem "brakeman"                # Security audit
  gem "bundler-audit"           # Dependency vulnerability check
end

group :test do
  gem "capybara"                # System tests
  gem "selenium-webdriver"      # Браузерные тесты
  gem "simplecov", require: false  # Покрытие кода
  gem "database_cleaner-active_record"
end
```

### 3. Установка зависимостей

```bash
bundle install
```

### 4. Настройка базы данных

```bash
bin/rails db:create
```

### 5. Инициализация Devise

```bash
bin/rails generate devise:install
bin/rails generate devise User
```

### 6. Инициализация RSpec

```bash
bin/rails generate rspec:install
```

### 7. Настройка Active Storage

```bash
bin/rails active_storage:install
```

Настроить `config/storage.yml` для MinIO (development):

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

minio:
  service: S3
  access_key_id: minioadmin
  secret_access_key: minioadmin
  region: us-east-1
  bucket: mediateca-dev
  endpoint: http://localhost:9000
  force_path_style: true
```

### 8. Запуск MinIO (development)

```bash
docker run -d \
  --name minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
```

Создать bucket:
```bash
docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
docker exec minio mc mb local/mediateca-dev
```

## Project Structure

```text
app/
├── controllers/
│   ├── media_files_controller.rb
│   ├── playlists_controller.rb
│   ├── auctions_controller.rb
│   ├── bids_controller.rb
│   ├── broadcasts_controller.rb
│   ├── balances_controller.rb
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
│   ├── auctions/
│   ├── broadcasts/
│   └── billing/
├── jobs/
├── views/
├── javascript/controllers/    # Stimulus
└── policies/                  # Pundit

spec/
├── models/
├── services/
├── requests/
├── system/
├── jobs/
├── policies/
├── factories/
└── support/
```

## Key Configuration

### Routes (config/routes.rb)

```ruby
Rails.application.routes.draw do
  devise_for :users

  # User-facing routes
  resources :media_files, only: [:index, :show, :create, :destroy]
  resources :playlists do
    resources :playlist_items, as: :items, only: [:create, :update, :destroy]
    patch :reorder, on: :member
  end
  resources :devices, only: [:index] do
    get :schedule, on: :member
  end
  resources :auctions, only: [:index, :show] do
    resources :bids, only: [:create]
  end
  resources :broadcasts, only: [:index, :create]
  resource :balance, only: [:show] do
    post :deposit
  end

  # Admin namespace
  namespace :admin do
    resources :devices do
      resources :time_slots, only: [:index] do
        post :generate, on: :collection
      end
    end
    resources :time_slots, only: [:update] do
      post :create_auction, on: :member
    end
    resources :device_groups do
      post :add_devices, on: :member
      delete "remove_device/:device_id", action: :remove_device, on: :member, as: :remove_device
    end
  end

  # Device API
  namespace :api do
    namespace :v1 do
      namespace :device do
        get :schedule
        post :heartbeat
        post :broadcast_status
      end
    end
  end

  root "media_files#index"
end
```

## Development Workflow

### TDD Cycle (обязательный — Constitution §II)

```bash
# 1. Write failing test
bin/rspec spec/models/media_file_spec.rb  # RED

# 2. Implement minimum code
# 3. Run test again
bin/rspec spec/models/media_file_spec.rb  # GREEN

# 4. Refactor
# 5. Run full suite
bin/rspec

# 6. Lint check
bin/rubocop

# 7. Security check
bin/brakeman --no-pager
bundle exec bundler-audit check --update
```

### Running the Application

```bash
bin/dev  # Запускает Rails server + Tailwind watcher + Solid Queue
```

## Implementation Order

Следуя приоритетам из спецификации:

1. **P1**: User model + Auth + Media Upload + Playlists (User Story 1)
2. **P2**: Admin namespace + BroadcastDevice + TimeSlot + Schedule (User Story 2)
3. **P3**: ScheduledBroadcast + Device schedule view (User Story 3)
4. **P4**: DeviceGroup + DeviceGroupMembership (User Story 4)
5. **P5**: Auction + Bid + AuctionCloseJob (User Story 5)
6. **P6**: Balance + Transaction + Billing services (User Story 6)
