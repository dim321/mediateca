class CreatePlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :playlists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :total_duration, null: false, default: 0
      t.integer :items_count, null: false, default: 0

      t.timestamps
    end

    add_index :playlists, [:user_id, :name], unique: true
  end
end
