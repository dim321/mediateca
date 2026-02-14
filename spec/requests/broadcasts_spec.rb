require "rails_helper"

RSpec.describe "Broadcasts", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }
  let(:device) { create(:broadcast_device) }

  before { sign_in user }

  describe "GET /broadcasts" do
    let!(:my_broadcast) { create(:scheduled_broadcast, user: user) }
    let!(:other_broadcast) { create(:scheduled_broadcast) }

    it "returns user's broadcasts" do
      get broadcasts_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      get broadcasts_path(status: "scheduled"), headers: html_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /broadcasts" do
    let(:time_slot) { create(:time_slot, :available, broadcast_device: device) }
    let(:playlist) { create(:playlist, user: user, total_duration: 1500) }

    it "creates a broadcast for available slot" do
      expect {
        post broadcasts_path, params: { broadcast: { playlist_id: playlist.id, time_slot_id: time_slot.id } }, headers: html_headers
      }.to change(ScheduledBroadcast, :count).by(1)
    end

    it "redirects on success" do
      post broadcasts_path, params: { broadcast: { playlist_id: playlist.id, time_slot_id: time_slot.id } }, headers: html_headers
      expect(response).to redirect_to(broadcasts_path)
    end

    context "when playlist duration exceeds slot" do
      let(:long_playlist) { create(:playlist, user: user, total_duration: 2000) }

      it "does not create a broadcast" do
        expect {
          post broadcasts_path, params: { broadcast: { playlist_id: long_playlist.id, time_slot_id: time_slot.id } }, headers: html_headers
        }.not_to change(ScheduledBroadcast, :count)
      end
    end

    context "when slot is not available" do
      let(:sold_slot) { create(:time_slot, :sold, broadcast_device: device) }

      it "does not create a broadcast" do
        expect {
          post broadcasts_path, params: { broadcast: { playlist_id: playlist.id, time_slot_id: sold_slot.id } }, headers: html_headers
        }.not_to change(ScheduledBroadcast, :count)
      end
    end
  end
end
