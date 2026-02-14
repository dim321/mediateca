class CreatePlaylistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :playlist_items do |t|
      t.references :playlist, null: false, foreign_key: true
      t.references :media_file, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :playlist_items, [:playlist_id, :position], unique: true
    add_index :playlist_items, [:playlist_id, :media_file_id], unique: true
  end
end
