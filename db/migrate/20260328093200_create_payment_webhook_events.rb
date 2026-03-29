class CreatePaymentWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_webhook_events do |t|
      t.integer :provider, null: false
      t.string :event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at

      t.timestamps
    end

    add_index :payment_webhook_events, [ :provider, :event_id ], unique: true, name: "index_payment_webhook_events_on_provider_and_event_id"
    add_index :payment_webhook_events, :processed_at, where: "processed_at IS NULL", name: "index_payment_webhook_events_unprocessed"
  end
end
