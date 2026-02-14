require "rails_helper"

RSpec.describe "Playlists", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /playlists" do
    let!(:my_playlist) { create(:playlist, user: user) }
    let!(:other_playlist) { create(:playlist, user: create(:user)) }

    it "returns user's playlists" do
      get playlists_path, headers: html_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ERB::Util.html_escape(my_playlist.name))
      expect(response.body).not_to include(ERB::Util.html_escape(other_playlist.name))
    end
  end

  describe "GET /playlists/:id" do
    let(:playlist) { create(:playlist, user: user) }

    it "shows the playlist with items" do
      get playlist_path(playlist), headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "denies access to another user's playlist" do
      other = create(:playlist, user: create(:user))
      get playlist_path(other), headers: html_headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /playlists" do
    it "creates a playlist with valid name" do
      expect {
        post playlists_path, params: { playlist: { name: "My Playlist", description: "Test" } }, headers: html_headers
      }.to change(Playlist, :count).by(1)
    end

    it "rejects playlist without name" do
      expect {
        post playlists_path, params: { playlist: { name: "" } }, headers: html_headers
      }.not_to change(Playlist, :count)
    end

    it "rejects duplicate name for same user" do
      create(:playlist, user: user, name: "My Playlist")
      expect {
        post playlists_path, params: { playlist: { name: "My Playlist" } }, headers: html_headers
      }.not_to change(Playlist, :count)
    end
  end

  describe "PATCH /playlists/:id" do
    let(:playlist) { create(:playlist, user: user, name: "Old Name") }

    it "updates the playlist name" do
      patch playlist_path(playlist), params: { playlist: { name: "New Name" } }, headers: html_headers
      expect(playlist.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /playlists/:id" do
    let!(:playlist) { create(:playlist, user: user) }

    it "deletes the playlist" do
      expect {
        delete playlist_path(playlist), headers: html_headers
      }.to change(Playlist, :count).by(-1)
    end
  end

  describe "PATCH /playlists/:id/reorder" do
    let(:playlist) { create(:playlist, user: user) }
    let(:file1) { create(:media_file, :ready, user: user, duration: 60) }
    let(:file2) { create(:media_file, :ready, user: user, duration: 120) }
    let!(:item1) { create(:playlist_item, playlist: playlist, media_file: file1, position: 1) }
    let!(:item2) { create(:playlist_item, playlist: playlist, media_file: file2, position: 2) }

    it "reorders items" do
      patch reorder_playlist_path(playlist),
            params: { item_ids: [item2.id, item1.id] },
            headers: html_headers
      expect(item2.reload.position).to eq(1)
      expect(item1.reload.position).to eq(2)
    end
  end
end
