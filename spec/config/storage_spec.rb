require "rails_helper"

RSpec.describe "Active Storage configuration" do
  let(:storage_config) do
    YAML.safe_load(
      ERB.new(Rails.root.join("config/storage.yml").read).result,
      aliases: true
    )
  end

  it "configures Yandex S3 checksum handling for S3-compatible storage" do
    yandex_config = storage_config.fetch("yandex")

    expect(yandex_config.fetch("request_checksum_calculation")).to eq("when_required")
    expect(yandex_config.fetch("response_checksum_validation")).to eq("when_required")
  end
end
