require 'rails_helper'

RSpec.describe RebillValidator do
  describe ".valid?" do
    let(:valid_amount) { 100.0 }
    let(:invalid_amount) { -10.0 }
    let(:valid_subscription_id) { 1 }
    let(:invalid_subscription_id) { -1 }

    before do
      allow(Subscription).to receive(:exists?).with(valid_subscription_id).and_return(true)
      allow(Subscription).to receive(:exists?).with(invalid_subscription_id).and_return(false)
    end

    context "when amount is positive and subscription_id exists" do
      it "returns true" do
        expect(RebillValidator.valid?(amount: valid_amount, subscription_id: valid_subscription_id)).to be(true)
      end
    end

    context "when amount is non-positive" do
      it "returns false" do
        expect(RebillValidator.valid?(amount: invalid_amount, subscription_id: valid_subscription_id)).to be(false)
      end
    end

    context "when subscription_id does not exist" do
      it "returns false" do
        expect(RebillValidator.valid?(amount: valid_amount, subscription_id: invalid_subscription_id)).to be(false)
      end
    end

    context "when subscription_id is invalid and amount is non-positive" do
      it "returns false" do
        expect(RebillValidator.valid?(amount: invalid_amount, subscription_id: invalid_subscription_id)).to be(false)
      end
    end

    context "when subscription_id is not a number" do
      it "returns false" do
        expect(RebillValidator.valid?(amount: valid_amount, subscription_id: "invalid_id")).to be(false)
      end
    end
  end
end

