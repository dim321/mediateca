# Деплой Mediateca в Yandex Cloud с Kamal

Деплой приложения на виртуальную машину в Yandex Cloud. Образы хранятся в Yandex Container Registry, PostgreSQL 18 развёрнут на той же VM как accessory.

## Требования

- Виртуальная машина в Yandex Cloud (Ubuntu 22.04 рекомендуется)
- Учётная запись в Yandex Container Registry с правами **pusher**
- SSH-доступ к VM по ключу (пользователь с правами на Docker)

## 1. Подготовка VM в Yandex Cloud

1. Создайте VM (Ubuntu 22.04), откройте порты 80, 443, 22.
2. Установите Docker на VM (Kamal сделает это при первом запуске, если включён `kamal server bootstrap`, либо установите вручную).
3. Запомните публичный IP или hostname VM.

Документация: [Yandex Cloud — создание VM](https://cloud.yandex.ru/docs/compute/quickstart/quick-create-linux)

## 2. Регистрация в Yandex Container Registry

1. Создайте registry в консоли Yandex Cloud.
2. Создайте репозиторий или используйте автоматически создаваемый при первом push.
3. Создайте учётную запись с правами **pusher** (или используйте OAuth-токен для доступа к registry).
4. Узнайте **Registry ID** (например, `crp9xxxxxxxxxxxxxxxx`) — он нужен для поля `image` в `config/deploy.yml`.

Документация: [Аутентификация в Container Registry](https://cloud.yandex.ru/docs/container-registry/operations/authentication)

## 3. Настройка конфигурации

### 3.1. config/deploy.yml

Замените плейсхолдеры:

| Плейсхолдер | Значение |
|-------------|----------|
| `REGISTRY_ID` | ID вашего registry в Yandex CR (например, `crp9xxxxxxxxxxxxxxxx`) |
| `YOUR_VM_IP_OR_HOSTNAME` | Публичный IP или hostname вашей VM (в секциях `servers.web` и `accessories.db.host`) |

Для логина в registry:
- **Pusher-аккаунт**: в `registry.username` укажите идентификатор учётной записи, в секретах — пароль.
- **OAuth**: оставьте `username: oauth`, в секретах — OAuth-токен.

### 3.2. Секреты (.kamal/secrets)

Файл `.kamal/secrets` задаёт переменные для Kamal. Не коммитьте в репозиторий реальные пароли.

Раскомментируйте и задайте:

```bash
# Пароль или OAuth-токен для входа в cr.yandex
KAMAL_REGISTRY_PASSWORD=<ваш пароль или OAuth-токен>

# Пароль пользователя БД (приложение и PostgreSQL). Задайте один раз, затем используйте для POSTGRES_PASSWORD.
MEDIATECA_DATABASE_PASSWORD=<надёжный пароль>

# Пароль пользователя postgres в контейнере (можно совпадать с MEDIATECA_DATABASE_PASSWORD)
POSTGRES_PASSWORD=$MEDIATECA_DATABASE_PASSWORD
```

Убедитесь, что `config/master.key` есть локально (для `RAILS_MASTER_KEY`).

## 4. Подготовка сервера (первый раз)

Установка Docker и настроек на VM (если ещё не установлено):

```bash
bundle exec kamal server bootstrap
```

Либо установите Docker на VM вручную и настройте SSH-доступ.

## 5. Запуск PostgreSQL (accessory)

Перед первым деплоем приложения поднимите базу:

```bash
bundle exec kamal accessory boot db
```

Проверка: `bundle exec kamal accessory details db`

## 6. Деплой приложения

```bash
# Сборка образа и push в Yandex CR
bundle exec kamal build push

# Деплой на сервер
bundle exec kamal deploy
```

При первом деплое будут выполнены `db:prepare` (создание БД и миграции) через entrypoint контейнера.

## 7. Полезные команды

| Команда | Описание |
|---------|----------|
| `bundle exec kamal deploy` | Полный деплой (build, push, deploy) |
| `bundle exec kamal app logs -f` | Логи приложения |
| `bundle exec kamal app exec -i --reuse "bin/rails console"` | Rails console |
| `bundle exec kamal accessory reboot db` | Перезапуск PostgreSQL |
| `bundle exec kamal app exec -i --reuse "bin/rails dbconsole --include-password"` | Подключение к БД |

## 8. SSL (опционально)

Когда DNS указывает на вашу VM, раскомментируйте в `config/deploy.yml` секцию `proxy` и укажите ваш домен:

```yaml
proxy:
  ssl: true
  host: app.example.com
```

В `config/environments/production.rb` должны быть включены `config.assume_ssl` и `config.force_ssl`.

## Структура

- **config/deploy.yml** — конфигурация Kamal (registry, серверы, env, accessory PostgreSQL 18).
- **db/production_setup.sql** — создание баз для Solid Cache, Solid Queue, Solid Cable при первом запуске PostgreSQL.
- **.kamal/secrets** — получение секретов из ENV/файлов (не храните в файле сырые пароли).

Базы данных на одном инстансе PostgreSQL 18:
- `mediateca_production` — основная
- `mediateca_production_cache` — Solid Cache
- `mediateca_production_queue` — Solid Queue  
- `mediateca_production_cable` — Solid Cable
