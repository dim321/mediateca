#!/usr/bin/env bash
# exit on error
set -o errexit

# Debug: show DATABASE_URL presence (without exposing credentials)
echo "[Render build] DATABASE_URL is ${DATABASE_URL:+set}"
echo "[Render build] RAILS_ENV=${RAILS_ENV:-development}"

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean

# Primary database
echo "[Render build] Running db:prepare (primary)..."
bundle exec rake db:prepare

# Explicit migrations for cache, queue, cable (Render has single DB - all use same)
echo "[Render build] Running db:migrate:cache..."
bundle exec rake db:migrate:cache
echo "[Render build] Running db:migrate:queue..."
bundle exec rake db:migrate:queue
echo "[Render build] Running db:migrate:cable..."
bundle exec rake db:migrate:cable

# Debug: show migration status (visible in Render build logs)
echo "[Render build] Migration status:"
bundle exec rake db:migrate:status:all
