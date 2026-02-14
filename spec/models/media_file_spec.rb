require "rails_helper"

RSpec.describe MediaFile, type: :model do
  subject(:media_file) { build(:media_file) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:media_type) }
    it { is_expected.to validate_presence_of(:format) }
    it { is_expected.to validate_inclusion_of(:format).in_array(%w[mp4 avi mov mp3 aac wav]) }
    it { is_expected.to validate_numericality_of(:file_size).is_less_than_or_equal_to(100.megabytes) }

    it "validates processing_status enum" do
      expect(media_file).to define_enum_for(:processing_status)
        .with_values(pending: 0, processing: 1, ready: 2, failed: 3)
    end

    it "validates media_type enum" do
      expect(media_file).to define_enum_for(:media_type)
        .with_values(audio: 0, video: 1)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:playlist_items).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:playlists).through(:playlist_items) }
    it "has one attached file" do
      expect(MediaFile.reflect_on_attachment(:file)).not_to be_nil
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:audio_file) { create(:media_file, :audio, user: user) }
    let!(:video_file) { create(:media_file, :video, user: user) }
    let!(:ready_file) { create(:media_file, :ready, user: user) }
    let!(:pending_file) { create(:media_file, :pending, user: user) }

    it "filters by audio type" do
      expect(described_class.audio).to include(audio_file)
      expect(described_class.audio).not_to include(video_file)
    end

    it "filters by video type" do
      expect(described_class.video).to include(video_file)
      expect(described_class.video).not_to include(audio_file)
    end

    it "filters by ready status" do
      expect(described_class.ready).to include(ready_file)
      expect(described_class.ready).not_to include(pending_file)
    end
  end
end
