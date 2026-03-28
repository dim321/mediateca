class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :financial_account, null: false, foreign_key: true
      t.integer :provider, null: false
      t.integer :operation_type, null: false
      t.integer :status, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.string :provider_payment_id
      t.string :provider_customer_id
      t.string :provider_checkout_session_id
      t.string :idempotency_key, null: false
      t.text :confirmation_url
      t.text :return_url
      t.string :failure_reason
      t.datetime :paid_at
      t.datetime :failed_at
      t.jsonb :metadata, null: false, default: {}
      t.jsonb :raw_response, null: false, default: {}

      t.timestamps
    end

    add_index :payments, :idempotency_key, unique: true
    add_index :payments, [ :provider, :provider_payment_id ], unique: true, where: "provider_payment_id IS NOT NULL", name: "index_payments_on_provider_and_provider_payment_id"
    add_index :payments, :status
    add_check_constraint :payments, "amount_cents > 0", name: "payments_amount_cents_positive"
  end
end
