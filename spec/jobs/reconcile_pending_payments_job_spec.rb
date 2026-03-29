require "rails_helper"

RSpec.describe ReconcilePendingPaymentsJob, type: :job do
  describe "#perform" do
    it "delegates to the reconciliation service" do
      service = instance_double(Payments::ReconcilePendingPayments, call: true)

      expect(Payments::ReconcilePendingPayments).to receive(:new).with(batch_size: 25).and_return(service)

      described_class.perform_now(batch_size: 25)
    end
  end
end
