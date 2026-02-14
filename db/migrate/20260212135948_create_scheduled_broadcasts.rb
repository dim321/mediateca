class CreateScheduledBroadcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_broadcasts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :playlist, null: false, foreign_key: true
      t.references :time_slot, null: false, foreign_key: true
      t.bigint :auction_id # FK will be added in US5 when auctions table exists
      t.integer :broadcast_status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :scheduled_broadcasts, :time_slot_id, unique: true, name: "index_scheduled_broadcasts_on_time_slot_unique"
    add_index :scheduled_broadcasts, [:user_id, :broadcast_status]
    add_index :scheduled_broadcasts, [:broadcast_status, :time_slot_id]
    add_index :scheduled_broadcasts, :auction_id
  end
end
