# frozen_string_literal: true

module MediaFilesHelper
  def processing_status_badge(media_file)
    status = media_file.processing_status&.to_sym

    status_config = {
      ready: { key: "processing_status.ready", classes: "bg-green-100 text-green-800" },
      pending: { key: "processing_status.pending", classes: "bg-yellow-100 text-yellow-800" },
      processing: { key: "processing_status.processing", classes: "bg-yellow-100 text-yellow-800" },
      failed: { key: "processing_status.failed", classes: "bg-red-100 text-red-800" }
    }.fetch(status, { key: "processing_status.unknown", classes: "bg-gray-100 text-gray-800" })

    content_tag(
      :span,
      t(status_config[:key]),
      class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_config[:classes]}"
    )
  end
end
