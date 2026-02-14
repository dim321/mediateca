require "rails_helper"

RSpec.describe "PlaylistItems", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }
  let(:playlist) { create(:playlist, user: user) }
  let(:media_file) { create(:media_file, :ready, user: user, duration: 120) }

  before { sign_in user }

  describe "POST /playlists/:playlist_id/items" do
    it "adds a media file to the playlist" do
      expect {
        post playlist_items_path(playlist),
             params: { playlist_item: { media_file_id: media_file.id, position: 1 } },
             headers: html_headers
      }.to change(PlaylistItem, :count).by(1)
    end

    it "prevents duplicate media file in same playlist" do
      create(:playlist_item, playlist: playlist, media_file: media_file, position: 1)
      expect {
        post playlist_items_path(playlist),
             params: { playlist_item: { media_file_id: media_file.id, position: 2 } },
             headers: html_headers
      }.not_to change(PlaylistItem, :count)
    end

    it "recalculates playlist total_duration" do
      post playlist_items_path(playlist),
           params: { playlist_item: { media_file_id: media_file.id, position: 1 } },
           headers: html_headers
      expect(playlist.reload.total_duration).to eq(120)
    end
  end

  describe "PATCH /playlists/:playlist_id/items/:id" do
    let(:file2) { create(:media_file, :ready, user: user, duration: 60) }
    let!(:item1) { create(:playlist_item, playlist: playlist, media_file: media_file, position: 1) }
    let!(:item2) { create(:playlist_item, playlist: playlist, media_file: file2, position: 2) }

    it "updates the item position" do
      # Move item1 to position 3 (new position, no conflict)
      patch playlist_item_path(playlist, item1),
            params: { playlist_item: { position: 3 } },
            headers: html_headers
      expect(item1.reload.position).to eq(3)
    end
  end

  describe "DELETE /playlists/:playlist_id/items/:id" do
    let!(:item) { create(:playlist_item, playlist: playlist, media_file: media_file, position: 1) }

    it "removes item from playlist" do
      expect {
        delete playlist_item_path(playlist, item), headers: html_headers
      }.to change(PlaylistItem, :count).by(-1)
    end

    it "recalculates playlist total_duration" do
      delete playlist_item_path(playlist, item), headers: html_headers
      expect(playlist.reload.total_duration).to eq(0)
    end
  end
end
