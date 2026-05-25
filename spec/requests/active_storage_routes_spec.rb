require "rails_helper"
require "digest"

RSpec.describe "Active Storage routes", type: :request do
  describe "POST /rails/active_storage/direct_uploads" do
    it "does not expose unauthenticated direct uploads" do
      blob_params = {
        filename: "payload.exe",
        byte_size: 1,
        checksum: Base64.strict_encode64(Digest::MD5.digest("x")),
        content_type: "application/octet-stream"
      }

      expect do
        post "/rails/active_storage/direct_uploads", params: { blob: blob_params }, as: :json
      end.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
