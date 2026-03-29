require "rails_helper"

RSpec.describe "Financial schema" do
  let(:connection) { ActiveRecord::Base.connection }

  before do
    financial_account_class.reset_column_information
    payment_class.reset_column_information
    payment_webhook_event_class.reset_column_information
  end

  let(:financial_account_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "financial_accounts"
    end
  end

  let(:payment_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "payments"
    end
  end

  let(:payment_webhook_event_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "payment_webhook_events"
    end
  end

  it "creates the new financial tables" do
    expect(connection.data_source_exists?("financial_accounts")).to be(true)
    expect(connection.data_source_exists?("payments")).to be(true)
    expect(connection.data_source_exists?("payment_webhook_events")).to be(true)
    expect(connection.data_source_exists?("ledger_entries")).to be(true)
  end

  it "enforces one financial account per user" do
    user = create(:user)
    begin
      financial_account_class.create!(
        user_id: user.id,
        currency: "RUB",
        available_amount_cents: 0,
        held_amount_cents: 0,
        status: 0
      )

      expect do
        financial_account_class.create!(
          user_id: user.id,
          currency: "RUB",
          available_amount_cents: 100,
          held_amount_cents: 0,
          status: 0
        )
      end.to raise_error(ActiveRecord::RecordNotUnique)
    ensure
      financial_account_class.where(user_id: user.id).delete_all
    end
  end

  it "prevents negative financial account amounts at the database level" do
    user = create(:user)
    account = nil

    begin
      account = financial_account_class.create!(
        user_id: user.id,
        currency: "RUB",
        available_amount_cents: 100,
        held_amount_cents: 0,
        status: 0
      )

      expect do
        financial_account_class.transaction(requires_new: true) do
          account.update_column(:available_amount_cents, -1)
        end
      end.to raise_error(ActiveRecord::StatementInvalid)
    ensure
      account&.delete
    end
  end

  it "enforces unique payment idempotency keys" do
    user = create(:user)
    account = financial_account_class.create!(
      user_id: user.id,
      currency: "RUB",
      available_amount_cents: 0,
      held_amount_cents: 0,
      status: 0
    )

    payment_class.create!(
      user_id: user.id,
      financial_account_id: account.id,
      provider: 0,
      operation_type: 0,
      status: 0,
      amount_cents: 1_000,
      currency: "RUB",
      idempotency_key: "top-up-1"
    )

    expect do
      payment_class.create!(
        user_id: user.id,
        financial_account_id: account.id,
        provider: 1,
        operation_type: 0,
        status: 0,
        amount_cents: 2_000,
        currency: "RUB",
        idempotency_key: "top-up-1"
      )
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "deduplicates webhook events by provider and event_id" do
    payment_webhook_event_class.create!(
      provider: 0,
      event_id: "evt_123",
      event_type: "payment.succeeded",
      payload: { "id" => "evt_123" }
    )

    expect do
      payment_webhook_event_class.create!(
        provider: 0,
        event_id: "evt_123",
        event_type: "payment.succeeded",
        payload: { "id" => "evt_123" }
      )
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "removes the legacy users.balance column" do
    expect(User.columns_hash).not_to have_key("balance")
  end

  it "drops the legacy transactions table" do
    expect(connection.data_source_exists?("transactions")).to be(false)
  end

  it "removes the legacy positive_balance check constraint from users" do
    constraint_names = connection.check_constraints("users").map(&:name)

    expect(constraint_names).not_to include("positive_balance")
  end

  it "adds an index for unprocessed webhook events" do
    index_names = connection.indexes("payment_webhook_events").map(&:name)

    expect(index_names).to include("index_payment_webhook_events_unprocessed")
  end

  it "does not keep a redundant single-column ledger account index" do
    index_names = connection.indexes("ledger_entries").map(&:name)

    expect(index_names).not_to include("index_ledger_entries_on_financial_account_id")
  end
end
