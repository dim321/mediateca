require "rails_helper"

RSpec.describe Playlist, type: :model do
  subject(:playlist) { build(:playlist, name: "My Playlist") }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id) }
    it { is_expected.to validate_numericality_of(:total_duration).is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:playlist_items).order(position: :asc).dependent(:destroy).inverse_of(:playlist) }
    it { is_expected.to have_many(:media_files).through(:playlist_items) }
  end

  describe "total_duration recalculation" do
    let(:user) { create(:user) }
    let(:playlist) { create(:playlist, user: user) }
    let(:file1) { create(:media_file, :ready, user: user, duration: 120) }
    let(:file2) { create(:media_file, :ready, user: user, duration: 180) }

    it "recalculates total_duration when items change" do
      create(:playlist_item, playlist: playlist, media_file: file1, position: 1)
      playlist.reload
      expect(playlist.total_duration).to eq(120)

      create(:playlist_item, playlist: playlist, media_file: file2, position: 2)
      playlist.reload
      expect(playlist.total_duration).to eq(300)
    end

    it "recalculates on item removal" do
      item = create(:playlist_item, playlist: playlist, media_file: file1, position: 1)
      create(:playlist_item, playlist: playlist, media_file: file2, position: 2)
      playlist.reload
      expect(playlist.total_duration).to eq(300)

      item.destroy
      playlist.reload
      expect(playlist.total_duration).to eq(180)
    end
  end
end
