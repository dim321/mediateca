class BackfillFinancialAccountsFromUsersBalance < ActiveRecord::Migration[8.1]
  def up
    # Legacy users.balance is stored in major currency units as decimal(12,2).
    # This backfill converts that value into integer cents with ROUND(balance * 100).
    # Under the current schema, users.balance is NOT NULL and protected by the
    # positive_balance check constraint, so null and negative legacy values are
    # rejected before this migration runs.
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
