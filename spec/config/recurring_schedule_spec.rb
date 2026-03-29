require "rails_helper"

RSpec.describe "config/recurring.yml" do
  let(:config) { YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true) }

  it "schedules payment reconciliation for production" do
    task = config.fetch("production").fetch("reconcile_pending_payments")

    expect(task).to include(
      "class" => "ReconcilePendingPaymentsJob",
      "queue" => "payments"
    )
    expect(task.fetch("schedule")).to be_present
  end
end
