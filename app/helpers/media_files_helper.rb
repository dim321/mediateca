# frozen_string_literal: true

module MediaFilesHelper
  def processing_status_badge(media_file)
    status = media_file.processing_status&.to_sym

    status_config = {
      ready: { text: "Готов", classes: "bg-green-100 text-green-800" },
      pending: { text: "Обработка...", classes: "bg-yellow-100 text-yellow-800" },
      processing: { text: "Обработка...", classes: "bg-yellow-100 text-yellow-800" },
      failed: { text: "Ошибка", classes: "bg-red-100 text-red-800" }
    }.fetch(status, { text: "Неизвестно", classes: "bg-gray-100 text-gray-800" })

    content_tag(
      :span,
      status_config[:text],
      class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_config[:classes]}"
    )
  end
end
