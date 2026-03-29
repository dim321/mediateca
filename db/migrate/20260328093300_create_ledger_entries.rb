class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :financial_account, null: false, foreign_key: true
      t.references :payment, foreign_key: true
      t.integer :entry_type, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.bigint :balance_after_cents, null: false
      t.bigint :held_after_cents, null: false
      t.string :description, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.string :idempotency_key
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :ledger_entries, [ :financial_account_id, :created_at ]
    add_index :ledger_entries, :idempotency_key
    add_index :ledger_entries, [ :reference_type, :reference_id ]
    add_check_constraint :ledger_entries, "amount_cents <> 0", name: "ledger_entries_amount_cents_non_zero"
    add_check_constraint :ledger_entries, "balance_after_cents >= 0", name: "ledger_entries_balance_after_cents_non_negative"
    add_check_constraint :ledger_entries, "held_after_cents >= 0", name: "ledger_entries_held_after_cents_non_negative"
  end
end
