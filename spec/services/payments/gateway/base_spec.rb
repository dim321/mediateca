require "rails_helper"

RSpec.describe Payments::Gateway::Base do
  describe "#create_top_up" do
    it "requires subclasses to implement the contract" do
      expect {
        described_class.new.create_top_up
      }.to raise_error(NotImplementedError, /must implement #create_top_up/)
    end
  end
end
