require "rails_helper"

RSpec.describe Media::UploadService do
  let(:user) { create(:user) }
  let(:valid_file) do
    fixture_file_upload(
      Rails.root.join("spec/fixtures/files/sample.mp3"),
      "audio/mpeg"
    )
  end

  describe "#call" do
    context "with valid file" do
      it "creates a MediaFile record" do
        expect {
          described_class.new(user: user, file: valid_file, title: "Test Track").call
        }.to change(MediaFile, :count).by(1)
      end

      it "sets processing_status to pending" do
        result = described_class.new(user: user, file: valid_file, title: "Test Track").call
        expect(result.media_file.processing_status).to eq("pending")
      end

      it "enqueues MediaProcessingJob" do
        expect {
          described_class.new(user: user, file: valid_file, title: "Test Track").call
        }.to have_enqueued_job(MediaProcessingJob)
      end

      it "attaches the file via Active Storage" do
        result = described_class.new(user: user, file: valid_file, title: "Test Track").call
        expect(result.media_file.file).to be_attached
      end
    end

    context "with invalid format" do
      let(:invalid_file) do
        fixture_file_upload(
          Rails.root.join("spec/fixtures/files/document.pdf"),
          "application/pdf"
        )
      end

      it "returns failure result" do
        result = described_class.new(user: user, file: invalid_file, title: "Bad File").call
        expect(result).not_to be_success
      end
    end

    context "with oversized file" do
      let(:oversized_file) do
        fixture_file_upload(
          Rails.root.join("spec/fixtures/files/sample.mp3"),
          "audio/mpeg"
        )
      end

      it "returns failure when file exceeds 100MB" do
        allow(oversized_file).to receive(:size).and_return(101.megabytes)
        result = described_class.new(user: user, file: oversized_file, title: "Big File").call
        expect(result).not_to be_success
      end
    end
  end
end
