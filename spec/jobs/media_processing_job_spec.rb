require "rails_helper"

RSpec.describe MediaProcessingJob, type: :job do
  let(:media_file) { create(:media_file, :pending, :with_file) }

  describe "#perform" do
    it "is enqueued in media_processing queue" do
      expect {
        described_class.perform_later(media_file.id)
      }.to have_enqueued_job(described_class).on_queue("media_processing")
    end

    context "when processing succeeds" do
      before do
        movie = instance_double(FFMPEG::Movie, duration: 245.5, valid?: true)
        allow(FFMPEG::Movie).to receive(:new).and_return(movie)
        # Mock Active Storage file.open
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:open).and_yield(
          Tempfile.new(["test", ".mp3"])
        )
      end

      it "updates processing_status to ready" do
        described_class.perform_now(media_file.id)
        media_file.reload
        expect(media_file.processing_status).to eq("ready")
      end

      it "extracts duration from the file" do
        described_class.perform_now(media_file.id)
        media_file.reload
        expect(media_file.duration).to eq(245)
      end
    end

    context "when processing fails" do
      before do
        allow(FFMPEG::Movie).to receive(:new).and_raise(FFMPEG::Error, "invalid file")
        allow_any_instance_of(ActiveStorage::Attached::One).to receive(:open).and_yield(
          Tempfile.new(["test", ".mp3"])
        )
      end

      it "updates processing_status to failed" do
        described_class.perform_now(media_file.id)
        media_file.reload
        expect(media_file.processing_status).to eq("failed")
      end
    end

    context "when media_file not found" do
      it "does not raise error" do
        expect { described_class.perform_now(-1) }.not_to raise_error
      end
    end
  end
end
