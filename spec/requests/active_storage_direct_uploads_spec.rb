require "rails_helper"

RSpec.describe "Active Storage direct uploads", type: :request do
  let(:blob_params) do
    {
      filename: "sample.mp3",
      content_type: "audio/mpeg",
      byte_size: 1.megabyte,
      checksum: "checksum"
    }
  end

  describe "POST /rails/active_storage/direct_uploads" do
    it "rejects unauthenticated direct uploads before issuing a storage URL" do
      expect {
        post rails_direct_uploads_path, params: { blob: blob_params }, as: :json
      }.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects oversized direct uploads for authenticated users" do
      sign_in create(:user)

      expect {
        post rails_direct_uploads_path,
          params: { blob: blob_params.merge(byte_size: Media::ValidationService::MAX_FILE_SIZE + 1) },
          as: :json
      }.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
