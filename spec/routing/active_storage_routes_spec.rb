require "rails_helper"

RSpec.describe "Active Storage routes", type: :routing do
  it "does not expose the default direct upload endpoint" do
    expect(post: "/rails/active_storage/direct_uploads").not_to be_routable
  end
end
