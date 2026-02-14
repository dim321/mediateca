require "rails_helper"

RSpec.describe "MediaFiles", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /media_files" do
    let!(:audio_file) { create(:media_file, :audio, user: user) }
    let!(:video_file) { create(:media_file, :video, user: user) }
    let!(:other_user_file) { create(:media_file, user: create(:user)) }

    it "returns user's media files" do
      get media_files_path, headers: html_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(audio_file.title)
      expect(response.body).not_to include(other_user_file.title)
    end

    it "filters by media_type" do
      get media_files_path(media_type: "audio"), headers: html_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(audio_file.title)
      expect(response.body).not_to include(video_file.title)
    end

    it "paginates results" do
      create_list(:media_file, 25, user: user)
      get media_files_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /media_files/:id" do
    let(:media_file) { create(:media_file, user: user) }
    let(:other_file) { create(:media_file, user: create(:user)) }

    it "shows the owner's file" do
      get media_file_path(media_file), headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "denies access to another user's file" do
      get media_file_path(other_file), headers: html_headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /media_files" do
    let(:valid_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.mp3"), "audio/mpeg") }

    it "creates a media file with valid data" do
      expect {
        post media_files_path, params: { media_file: { title: "My Track", file: valid_file } }, headers: html_headers
      }.to change(MediaFile, :count).by(1)
    end

    it "rejects upload without title" do
      expect {
        post media_files_path, params: { media_file: { title: "", file: valid_file } }, headers: html_headers
      }.not_to change(MediaFile, :count)
    end
  end

  describe "DELETE /media_files/:id" do
    let!(:media_file) { create(:media_file, user: user) }

    it "deletes user's own file" do
      expect {
        delete media_file_path(media_file), headers: html_headers
      }.to change(MediaFile, :count).by(-1)
    end

    context "when file is in a playlist" do
      before do
        playlist = create(:playlist, user: user)
        create(:playlist_item, playlist: playlist, media_file: media_file, position: 1)
      end

      it "prevents deletion" do
        expect {
          delete media_file_path(media_file), headers: html_headers
        }.not_to change(MediaFile, :count)
      end
    end
  end
end
