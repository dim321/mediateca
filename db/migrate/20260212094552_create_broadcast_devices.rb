class CreateBroadcastDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :broadcast_devices do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.string :address, null: false
      t.string :time_zone, null: false, default: "UTC"
      t.integer :status, null: false, default: 0
      t.string :api_token, null: false
      t.datetime :last_heartbeat_at
      t.text :description

      t.timestamps
    end

    add_index :broadcast_devices, :city
    add_index :broadcast_devices, :status
    add_index :broadcast_devices, :api_token, unique: true
  end
end
