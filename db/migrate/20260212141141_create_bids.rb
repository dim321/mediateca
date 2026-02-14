class CreateBids < ActiveRecord::Migration[8.1]
  def change
    create_table :bids do |t|
      t.references :auction, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.datetime :created_at, null: false
    end

    add_index :bids, [:auction_id, :amount]
    add_index :bids, [:auction_id, :created_at]
  end
end
