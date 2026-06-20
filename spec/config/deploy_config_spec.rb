require "rails_helper"
require "yaml"

RSpec.describe "Kamal deploy config" do
  it "injects the production object storage bucket into the app container" do
    deploy_config = YAML.load_file(Rails.root.join("config/deploy.yml"))
    secret_names = deploy_config.fetch("env").fetch("secret")

    expect(secret_names).to include("YC_BUCKET")
  end

  it "declares the object storage bucket in Kamal secrets" do
    secrets = Rails.root.join(".kamal/secrets").read

    expect(secrets).to include("YC_BUCKET=${YC_BUCKET}")
  end
end
