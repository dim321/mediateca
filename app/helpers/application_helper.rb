module ApplicationHelper
  CURRENCY_FORMATS = {
    "RUB" => { unit: "₽", format: "%n %u" },
    "USD" => { unit: "$", format: "%u%n" },
    "EUR" => { unit: "€", format: "%u%n" },
    "GBP" => { unit: "£", format: "%u%n" },
    "GEL" => { unit: "₾", format: "%n %u" },
    "JPY" => { unit: "¥", format: "%u%n" },
    "KZT" => { unit: "₸", format: "%n %u" },
    "UAH" => { unit: "₴", format: "%n %u" }
  }.freeze

  def status_badge(status)
    s = status.to_s
    css = s == "online" ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
    tag.span(t("devices.status.#{s}", default: s), class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end

  def format_money(amount, currency:)
    config = CURRENCY_FORMATS.fetch(currency.to_s.upcase, { unit: currency.to_s.upcase, format: "%n %u" })
    number_to_currency(amount, unit: config.fetch(:unit), format: config.fetch(:format))
  end
end
