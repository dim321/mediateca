# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_28_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "auctions", force: :cascade do |t|
    t.integer "auction_status", default: 0, null: false
    t.datetime "closes_at", null: false
    t.datetime "created_at", null: false
    t.decimal "current_highest_bid", precision: 10, scale: 2
    t.bigint "highest_bidder_id"
    t.integer "lock_version", default: 0, null: false
    t.decimal "starting_price", precision: 10, scale: 2, null: false
    t.bigint "time_slot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_status", "closes_at"], name: "index_auctions_on_auction_status_and_closes_at"
    t.index ["highest_bidder_id"], name: "index_auctions_on_highest_bidder_id"
    t.index ["time_slot_id"], name: "index_auctions_on_time_slot_id", unique: true
  end

  create_table "bids", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "auction_id", null: false
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.index ["auction_id", "amount"], name: "index_bids_on_auction_id_and_amount"
    t.index ["auction_id", "created_at"], name: "index_bids_on_auction_id_and_created_at"
    t.index ["auction_id"], name: "index_bids_on_auction_id"
    t.index ["user_id"], name: "index_bids_on_user_id"
  end

  create_table "broadcast_devices", force: :cascade do |t|
    t.string "address", null: false
    t.string "api_token", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "last_heartbeat_at"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_broadcast_devices_on_api_token", unique: true
    t.index ["city"], name: "index_broadcast_devices_on_city"
    t.index ["status"], name: "index_broadcast_devices_on_status"
  end

  create_table "device_group_memberships", force: :cascade do |t|
    t.bigint "broadcast_device_id", null: false
    t.datetime "created_at", null: false
    t.bigint "device_group_id", null: false
    t.index ["broadcast_device_id", "device_group_id"], name: "index_device_group_memberships_uniqueness", unique: true
    t.index ["broadcast_device_id"], name: "index_device_group_memberships_on_broadcast_device_id"
    t.index ["device_group_id"], name: "index_device_group_memberships_on_device_group_id"
  end

  create_table "device_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "devices_count", default: 0, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_device_groups_on_name", unique: true
  end

  create_table "financial_accounts", force: :cascade do |t|
    t.bigint "available_amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB", null: false
    t.bigint "held_amount_cents", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_financial_accounts_on_user_id", unique: true
    t.check_constraint "available_amount_cents >= 0", name: "financial_accounts_available_amount_cents_non_negative"
    t.check_constraint "held_amount_cents >= 0", name: "financial_accounts_held_amount_cents_non_negative"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.bigint "balance_after_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.string "description", null: false
    t.integer "entry_type", null: false
    t.bigint "financial_account_id", null: false
    t.bigint "held_after_cents", null: false
    t.string "idempotency_key"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "payment_id"
    t.bigint "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", null: false
    t.index ["financial_account_id", "created_at"], name: "index_ledger_entries_on_financial_account_id_and_created_at"
    t.index ["idempotency_key"], name: "index_ledger_entries_on_idempotency_key"
    t.index ["payment_id"], name: "index_ledger_entries_on_payment_id"
    t.index ["reference_type", "reference_id"], name: "index_ledger_entries_on_reference_type_and_reference_id"
    t.check_constraint "amount_cents <> 0", name: "ledger_entries_amount_cents_non_zero"
    t.check_constraint "balance_after_cents >= 0", name: "ledger_entries_balance_after_cents_non_negative"
    t.check_constraint "held_after_cents >= 0", name: "ledger_entries_held_after_cents_non_negative"
  end

  create_table "media_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration"
    t.bigint "file_size", null: false
    t.string "format", null: false
    t.integer "media_type", null: false
    t.integer "processing_status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_media_files_on_user_id_and_created_at"
    t.index ["user_id", "media_type"], name: "index_media_files_on_user_id_and_media_type"
    t.index ["user_id"], name: "index_media_files_on_user_id"
  end

  create_table "payment_webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.integer "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["processed_at"], name: "index_payment_webhook_events_unprocessed", where: "(processed_at IS NULL)"
    t.index ["provider", "event_id"], name: "index_payment_webhook_events_on_provider_and_event_id", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.text "confirmation_url"
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.datetime "failed_at"
    t.string "failure_reason"
    t.bigint "financial_account_id", null: false
    t.string "idempotency_key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "operation_type", null: false
    t.datetime "paid_at"
    t.integer "provider", null: false
    t.string "provider_checkout_session_id"
    t.string "provider_customer_id"
    t.string "provider_payment_id"
    t.jsonb "raw_response", default: {}, null: false
    t.text "return_url"
    t.integer "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["financial_account_id"], name: "index_payments_on_financial_account_id"
    t.index ["idempotency_key"], name: "index_payments_on_idempotency_key", unique: true
    t.index ["provider", "provider_payment_id"], name: "index_payments_on_provider_and_provider_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
    t.check_constraint "amount_cents > 0", name: "payments_amount_cents_positive"
  end

  create_table "playlist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "media_file_id", null: false
    t.bigint "playlist_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["media_file_id"], name: "index_playlist_items_on_media_file_id"
    t.index ["playlist_id", "media_file_id"], name: "index_playlist_items_on_playlist_id_and_media_file_id", unique: true
    t.index ["playlist_id", "position"], name: "index_playlist_items_on_playlist_id_and_position", unique: true
    t.index ["playlist_id"], name: "index_playlist_items_on_playlist_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "items_count", default: 0, null: false
    t.string "name", null: false
    t.integer "total_duration", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_playlists_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_playlists_on_user_id"
  end

  create_table "scheduled_broadcasts", force: :cascade do |t|
    t.bigint "auction_id"
    t.integer "broadcast_status", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "playlist_id", null: false
    t.datetime "started_at"
    t.bigint "time_slot_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["auction_id"], name: "index_scheduled_broadcasts_on_auction_id"
    t.index ["broadcast_status", "time_slot_id"], name: "idx_on_broadcast_status_time_slot_id_7963a5b807"
    t.index ["playlist_id"], name: "index_scheduled_broadcasts_on_playlist_id"
    t.index ["time_slot_id"], name: "index_scheduled_broadcasts_on_time_slot_id"
    t.index ["time_slot_id"], name: "index_scheduled_broadcasts_on_time_slot_unique", unique: true
    t.index ["user_id", "broadcast_status"], name: "index_scheduled_broadcasts_on_user_id_and_broadcast_status"
    t.index ["user_id"], name: "index_scheduled_broadcasts_on_user_id"
  end

  create_table "time_slots", force: :cascade do |t|
    t.bigint "broadcast_device_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end_time", null: false
    t.integer "slot_status", default: 0, null: false
    t.datetime "start_time", null: false
    t.decimal "starting_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["broadcast_device_id", "slot_status"], name: "index_time_slots_on_broadcast_device_id_and_slot_status"
    t.index ["broadcast_device_id", "start_time"], name: "index_time_slots_on_broadcast_device_id_and_start_time", unique: true
    t.index ["broadcast_device_id"], name: "index_time_slots_on_broadcast_device_id"
    t.index ["start_time"], name: "index_time_slots_on_start_time"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "reference_id"
    t.string "reference_type"
    t.integer "transaction_type", null: false
    t.bigint "user_id", null: false
    t.index ["reference_type", "reference_id"], name: "index_transactions_on_reference_type_and_reference_id"
    t.index ["user_id", "created_at"], name: "index_transactions_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "auctions", "time_slots"
  add_foreign_key "auctions", "users", column: "highest_bidder_id"
  add_foreign_key "bids", "auctions"
  add_foreign_key "bids", "users"
  add_foreign_key "device_group_memberships", "broadcast_devices"
  add_foreign_key "device_group_memberships", "device_groups"
  add_foreign_key "financial_accounts", "users"
  add_foreign_key "ledger_entries", "financial_accounts"
  add_foreign_key "ledger_entries", "payments"
  add_foreign_key "media_files", "users"
  add_foreign_key "payments", "financial_accounts"
  add_foreign_key "payments", "users"
  add_foreign_key "playlist_items", "media_files"
  add_foreign_key "playlist_items", "playlists"
  add_foreign_key "playlists", "users"
  add_foreign_key "scheduled_broadcasts", "playlists"
  add_foreign_key "scheduled_broadcasts", "time_slots"
  add_foreign_key "scheduled_broadcasts", "users"
  add_foreign_key "time_slots", "broadcast_devices"
  add_foreign_key "transactions", "users"
end
