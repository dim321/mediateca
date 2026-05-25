require "rails_helper"
require "digest"

RSpec.describe "Active Storage routes", type: :request do
  describe "POST /rails/active_storage/direct_uploads" do
    let(:blob_params) do
      {
        filename: "payload.exe",
        byte_size: 1,
        checksum: Base64.strict_encode64(Digest::MD5.digest("x")),
        content_type: "application/octet-stream"
      }
    end

    it "does not expose unauthenticated direct uploads" do
      expect do
        post "/rails/active_storage/direct_uploads", params: { blob: blob_params }, as: :json
      end.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not let signed-in users bypass media upload validation" do
      sign_in create(:user)

      expect do
        post "/rails/active_storage/direct_uploads", params: { blob: blob_params }, as: :json
      end.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
