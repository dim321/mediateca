class CreateAuctions < ActiveRecord::Migration[8.1]
  def change
    create_table :auctions do |t|
      t.references :time_slot, null: false, foreign_key: true, index: false
      t.decimal :starting_price, precision: 10, scale: 2, null: false
      t.decimal :current_highest_bid, precision: 10, scale: 2
      t.bigint :highest_bidder_id
      t.datetime :closes_at, null: false
      t.integer :auction_status, null: false, default: 0
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :auctions, :time_slot_id, unique: true
    add_index :auctions, [:auction_status, :closes_at]
    add_index :auctions, :highest_bidder_id
    add_foreign_key :auctions, :users, column: :highest_bidder_id
  end
end
