class CreateTimeSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :time_slots do |t|
      t.references :broadcast_device, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.decimal :starting_price, precision: 12, scale: 2, null: false, default: 0
      t.integer :slot_status, null: false, default: 0

      t.timestamps
    end

    add_index :time_slots, [:broadcast_device_id, :start_time], unique: true
    add_index :time_slots, [:broadcast_device_id, :slot_status]
    add_index :time_slots, :start_time
  end
end
