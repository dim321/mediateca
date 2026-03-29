Rails.configuration.x.stripe = ActiveSupport::OrderedOptions.new
Rails.configuration.x.stripe.secret_key =
  ENV["STRIPE_SECRET_KEY"].presence || Rails.application.credentials.dig(:stripe, :secret_key)
Rails.configuration.x.stripe.webhook_secret =
  ENV["STRIPE_WEBHOOK_SECRET"].presence || Rails.application.credentials.dig(:stripe, :webhook_secret)
Rails.configuration.x.stripe.publishable_key =
  ENV["STRIPE_PUBLISHABLE_KEY"].presence || Rails.application.credentials.dig(:stripe, :publishable_key)

module StripeConfig
  SOURCES = {
    secret_key: "STRIPE_SECRET_KEY or credentials.stripe[:secret_key]",
    webhook_secret: "STRIPE_WEBHOOK_SECRET or credentials.stripe[:webhook_secret]",
    publishable_key: "STRIPE_PUBLISHABLE_KEY or credentials.stripe[:publishable_key]"
  }.freeze

  module_function

  def configured?
    settings.secret_key.present? && settings.webhook_secret.present?
  end

  def secret_key!
    fetch!(:secret_key)
  end

  def webhook_secret!
    fetch!(:webhook_secret)
  end

  def publishable_key!
    fetch!(:publishable_key)
  end

  def settings
    Rails.configuration.x.stripe
  end

  def fetch!(key)
    value = settings.public_send(key)
    return value if value.present?

    raise KeyError, "Missing Stripe configuration for #{key}. Set #{SOURCES.fetch(key)}."
  end
end

Stripe.api_key = StripeConfig.settings.secret_key if StripeConfig.settings.secret_key.present?
