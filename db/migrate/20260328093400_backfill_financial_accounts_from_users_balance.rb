class BackfillFinancialAccountsFromUsersBalance < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO financial_accounts (
        user_id,
        currency,
        available_amount_cents,
        held_amount_cents,
        status,
        created_at,
        updated_at
      )
      SELECT
        users.id,
        'RUB',
        ROUND(users.balance * 100)::bigint,
        0,
        0,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM users
      WHERE NOT EXISTS (
        SELECT 1
        FROM financial_accounts
        WHERE financial_accounts.user_id = users.id
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Financial account backfill cannot be reversed safely."
  end
end
