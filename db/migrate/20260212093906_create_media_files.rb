class CreateMediaFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :media_files do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :media_type, null: false
      t.string :format, null: false
      t.integer :duration
      t.bigint :file_size, null: false
      t.integer :processing_status, null: false, default: 0

      t.timestamps
    end

    add_index :media_files, [:user_id, :media_type]
    add_index :media_files, [:user_id, :created_at]
  end
end
