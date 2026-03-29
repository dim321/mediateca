require "rails_helper"

RSpec.describe PaymentWebhookEvent, type: :model do
  subject(:payment_webhook_event) { build(:payment_webhook_event) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:event_id) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:payload) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:provider).with_values(stripe: 0, yookassa: 1) }
  end

  describe "scopes" do
    it "returns only unprocessed events" do
      unprocessed = create(:payment_webhook_event, processed_at: nil)
      create(:payment_webhook_event, processed_at: Time.current)

      expect(described_class.unprocessed).to contain_exactly(unprocessed)
    end
  end
end
