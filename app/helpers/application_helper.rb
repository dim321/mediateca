module ApplicationHelper
  def status_badge(status)
    css = status.to_s == "online" ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
    tag.span(status, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end
end
