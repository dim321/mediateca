require "rails_helper"

RSpec.describe "TopUps", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }
  let!(:financial_account) { create(:financial_account, user: user, currency: "USD") }
  let(:gateway_response) do
    Payments::Gateway::Base::Response.new(
      provider_payment_id: "provider-payment-123",
      provider_checkout_session_id: "provider-session-123",
      confirmation_url: "https://provider.test/checkout",
      raw_response: { "id" => "provider-payment-123" }
    )
  end

  before { sign_in user }

  describe "POST /top_ups" do
    it "creates a stripe top-up and redirects to the provider confirmation page" do
      gateway = instance_double(Payments::Gateway::StripeStrategy, create_top_up: gateway_response)
      allow(Payments::GatewayResolver).to receive(:call).with(provider: "stripe").and_return(gateway)

      expect {
        post top_ups_path, params: { top_up: { provider: "stripe", amount: "99.50" } }, headers: html_headers
      }.to change(Payment, :count).by(1)

      expect(response).to redirect_to("https://provider.test/checkout")
      payment = Payment.order(:id).last
      expect(payment).to be_pending
      expect(payment.provider).to eq("stripe")
      expect(payment.amount_cents).to eq(9_950)
      expect(payment.currency).to eq("USD")
    end

    it "creates a yookassa top-up and redirects to the provider confirmation page" do
      gateway = instance_double(Payments::Gateway::YookassaStrategy, create_top_up: gateway_response)
      allow(Payments::GatewayResolver).to receive(:call).with(provider: "yookassa").and_return(gateway)

      post top_ups_path, params: { top_up: { provider: "yookassa", amount: "50.00" } }, headers: html_headers

      expect(response).to redirect_to("https://provider.test/checkout")
      expect(Payment.order(:id).last.provider).to eq("yookassa")
    end

    it "redirects back to balance for an invalid provider" do
      expect {
        post top_ups_path, params: { top_up: { provider: "paypal", amount: "20.00" } }, headers: html_headers
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(balance_path)
      follow_redirect!
      expect(response.body).to include("Unsupported payment provider")
    end

    it "redirects back to balance for an invalid amount" do
      expect {
        post top_ups_path, params: { top_up: { provider: "stripe", amount: "0" } }, headers: html_headers
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(balance_path)
      follow_redirect!
      expect(response.body).to include("Amount must be greater than 0")
    end
  end

  describe "GET /top_ups/success" do
    it "redirects back to balance with an awaiting confirmation notice" do
      get success_top_ups_path, headers: html_headers

      expect(response).to redirect_to(balance_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("top_ups.flash.awaiting_confirmation"))
    end
  end

  describe "GET /top_ups/cancel" do
    it "redirects back to balance with a cancel alert" do
      get cancel_top_ups_path, headers: html_headers

      expect(response).to redirect_to(balance_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("top_ups.flash.canceled"))
    end
  end
end
