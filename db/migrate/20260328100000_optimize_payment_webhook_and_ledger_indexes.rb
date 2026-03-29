class OptimizePaymentWebhookAndLedgerIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :payment_webhook_events, :processed_at, where: "processed_at IS NULL", name: "index_payment_webhook_events_unprocessed", if_not_exists: true
    remove_index :ledger_entries, name: "index_ledger_entries_on_financial_account_id", if_exists: true
  end
end
