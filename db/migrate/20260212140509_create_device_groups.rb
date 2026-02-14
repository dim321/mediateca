class CreateDeviceGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :device_groups do |t|
      t.string :name, null: false
      t.text :description
      t.integer :devices_count, null: false, default: 0

      t.timestamps
    end

    add_index :device_groups, :name, unique: true
  end
end
