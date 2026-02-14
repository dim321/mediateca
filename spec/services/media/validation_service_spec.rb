require "rails_helper"

RSpec.describe Media::ValidationService do
  describe "#call" do
    let(:service) { described_class.new(file: file) }

    context "with valid audio formats" do
      %w[mp3 aac wav].each do |ext|
        it "accepts .#{ext} files" do
          file = double("file", original_filename: "test.#{ext}", content_type: "audio/mpeg", size: 5.megabytes)
          result = described_class.new(file: file).call
          expect(result).to be_success
        end
      end
    end

    context "with valid video formats" do
      %w[mp4 avi mov].each do |ext|
        it "accepts .#{ext} files" do
          file = double("file", original_filename: "test.#{ext}", content_type: "video/mp4", size: 10.megabytes)
          result = described_class.new(file: file).call
          expect(result).to be_success
        end
      end
    end

    context "with invalid formats" do
      %w[pdf txt exe doc].each do |ext|
        it "rejects .#{ext} files" do
          file = double("file", original_filename: "test.#{ext}", content_type: "application/pdf", size: 1.megabyte)
          result = described_class.new(file: file).call
          expect(result).not_to be_success
          expect(result.error).to include("формат")
        end
      end
    end

    context "with size validation" do
      it "accepts files up to 100MB" do
        file = double("file", original_filename: "test.mp3", content_type: "audio/mpeg", size: 100.megabytes)
        result = described_class.new(file: file).call
        expect(result).to be_success
      end

      it "rejects files over 100MB" do
        file = double("file", original_filename: "test.mp3", content_type: "audio/mpeg", size: 101.megabytes)
        result = described_class.new(file: file).call
        expect(result).not_to be_success
        expect(result.error).to include("размер")
      end
    end
  end
end
