Rails.configuration.x.yookassa = ActiveSupport::OrderedOptions.new
Rails.configuration.x.yookassa.shop_id =
  ENV["YOOKASSA_SHOP_ID"].presence || Rails.application.credentials.dig(:yookassa, :shop_id)
Rails.configuration.x.yookassa.secret_key =
  ENV["YOOKASSA_SECRET_KEY"].presence || Rails.application.credentials.dig(:yookassa, :secret_key)
Rails.configuration.x.yookassa.api_base_url =
  ENV["YOOKASSA_API_BASE_URL"].presence || Rails.application.credentials.dig(:yookassa, :api_base_url) || "https://api.yookassa.ru/v3"

module YookassaConfig
  SOURCES = {
    shop_id: "YOOKASSA_SHOP_ID or credentials.yookassa[:shop_id]",
    secret_key: "YOOKASSA_SECRET_KEY or credentials.yookassa[:secret_key]",
    api_base_url: "YOOKASSA_API_BASE_URL or credentials.yookassa[:api_base_url]"
  }.freeze

  module_function

  def configured?
    settings.shop_id.present? && settings.secret_key.present?
  end

  def shop_id!
    fetch!(:shop_id)
  end

  def secret_key!
    fetch!(:secret_key)
  end

  def api_base_url!
    fetch!(:api_base_url)
  end

  def settings
    Rails.configuration.x.yookassa
  end

  def fetch!(key)
    value = settings.public_send(key)
    return value if value.present?

    raise KeyError, "Missing YooKassa configuration for #{key}. Set #{SOURCES.fetch(key)}."
  end
end
