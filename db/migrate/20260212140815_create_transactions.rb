class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :transaction_type, null: false
      t.string :description, null: false
      t.string :reference_type
      t.bigint :reference_id

      t.datetime :created_at, null: false
    end

    add_index :transactions, [:user_id, :created_at]
    add_index :transactions, [:reference_type, :reference_id]
  end
end
