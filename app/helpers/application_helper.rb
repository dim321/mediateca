module ApplicationHelper
  def status_badge(status)
    s = status.to_s
    css = s == "online" ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
    tag.span(t("devices.status.#{s}", default: s), class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end
end
