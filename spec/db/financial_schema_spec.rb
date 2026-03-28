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

  it "backfills financial accounts from legacy user balances" do
    user = create(:user, balance: 123.45)
    migration_path = Dir[Rails.root.join("db/migrate/*_backfill_financial_accounts_from_users_balance.rb")].first
    load migration_path
    begin
      expect do
        ActiveRecord::Migration.suppress_messages do
          BackfillFinancialAccountsFromUsersBalance.new.migrate(:up)
        end
      end.to change { financial_account_class.where(user_id: user.id).count }.by(1)

      account = financial_account_class.find_by!(user_id: user.id)
      expect(account.available_amount_cents).to eq(12_345)
      expect(account.held_amount_cents).to eq(0)
      expect(account.currency).to eq("RUB")
    ensure
      financial_account_class.where(user_id: user.id).delete_all
    end
  end

  it "backfills integer major-unit balances into cents" do
    user = create(:user, balance: 123)
    migration_path = Dir[Rails.root.join("db/migrate/*_backfill_financial_accounts_from_users_balance.rb")].first
    load migration_path

    begin
      ActiveRecord::Migration.suppress_messages do
        BackfillFinancialAccountsFromUsersBalance.new.migrate(:up)
      end

      account = financial_account_class.find_by!(user_id: user.id)
      expect(account.available_amount_cents).to eq(12_300)
    ensure
      financial_account_class.where(user_id: user.id).delete_all
    end
  end

  it "backfills zero balances as zero cents" do
    user = create(:user, balance: 0)
    migration_path = Dir[Rails.root.join("db/migrate/*_backfill_financial_accounts_from_users_balance.rb")].first
    load migration_path

    begin
      ActiveRecord::Migration.suppress_messages do
        BackfillFinancialAccountsFromUsersBalance.new.migrate(:up)
      end

      account = financial_account_class.find_by!(user_id: user.id)
      expect(account.available_amount_cents).to eq(0)
    ensure
      financial_account_class.where(user_id: user.id).delete_all
    end
  end

  it "documents that legacy users.balance is stored in decimal major units, not cents" do
    balance_column = User.columns_hash.fetch("balance")

    expect(balance_column.type).to eq(:decimal)
    expect(balance_column.precision).to eq(12)
    expect(balance_column.scale).to eq(2)
    expect(balance_column.null).to be(false)
  end

  it "rejects negative legacy balances before backfill via positive_balance" do
    user = create(:user)

    expect do
      user.update_column(:balance, -1)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects null legacy balances before backfill" do
    user = create(:user)

    expect do
      user.update_column(:balance, nil)
    end.to raise_error(ActiveRecord::StatementInvalid)
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
