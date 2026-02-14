class CreateDeviceGroupMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :device_group_memberships do |t|
      t.references :broadcast_device, null: false, foreign_key: true
      t.references :device_group, null: false, foreign_key: true

      t.datetime :created_at, null: false
    end

    add_index :device_group_memberships, [:broadcast_device_id, :device_group_id],
              unique: true, name: "index_device_group_memberships_uniqueness"
  end
end
