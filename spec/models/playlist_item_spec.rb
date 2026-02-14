require "rails_helper"

RSpec.describe PlaylistItem, type: :model do
  subject(:playlist_item) { build(:playlist_item) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:position).scoped_to(:playlist_id) }
    it { is_expected.to validate_uniqueness_of(:media_file_id).scoped_to(:playlist_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:playlist).touch(true) }
    it { is_expected.to belong_to(:media_file) }
  end
end
