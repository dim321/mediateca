class CreateFinancialAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_accounts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :currency, null: false, default: "RUB"
      t.bigint :available_amount_cents, null: false, default: 0
      t.bigint :held_amount_cents, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :financial_accounts, "available_amount_cents >= 0", name: "financial_accounts_available_amount_cents_non_negative"
    add_check_constraint :financial_accounts, "held_amount_cents >= 0", name: "financial_accounts_held_amount_cents_non_negative"
  end
end
