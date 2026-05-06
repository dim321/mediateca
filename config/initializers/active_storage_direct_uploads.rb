# Protect the framework direct-upload endpoint: it is mounted outside
# ApplicationController, so it does not inherit the app-wide authenticate_user! hook.
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    unless private_method_defined?(:validate_media_direct_upload!)
      before_action :authenticate_user!
      before_action :validate_media_direct_upload!

      private

      def validate_media_direct_upload!
        return if allowed_media_direct_upload?

        render json: { error: "Unsupported media file or file is too large" }, status: :unprocessable_content
      end

      def allowed_media_direct_upload?
        Media::ValidationService::ALLOWED_FORMATS.include?(direct_upload_format) &&
          direct_upload_byte_size.positive? &&
          direct_upload_byte_size <= Media::ValidationService::MAX_FILE_SIZE
      end

      def direct_upload_format
        File.extname(params.dig(:blob, :filename).to_s).delete(".").downcase
      end

      def direct_upload_byte_size
        params.dig(:blob, :byte_size).to_i
      end
    end
  end
end
