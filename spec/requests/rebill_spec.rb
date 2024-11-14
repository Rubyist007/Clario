require 'rails_helper'

RSpec.describe "RebillController", type: :request do
  describe "POST /paymentIntents/create" do
    let(:valid_params) { { amount: 100, subscription_id: 1 } }
    let(:invalid_params) { { amount: -50, subscription_id: nil } }

    context "when params are valid and full rebill succeeds" do
      before do
        allow(RebillOperation).to receive(:call).and_return(double("RebillOperation", insufficient_funds?: false, full_rebill?: true))
      end

      it "returns a success response" do
        post "/paymentIntents/create", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("status" => "success")
      end
    end

    context "when params are valid and only a partial rebill succeeds" do
      before do
        allow(RebillOperation).to receive(:call).and_return(double("RebillOperation", insufficient_funds?: false, full_rebill?: false, partial_rebill?: true))
      end

      it "returns a success response" do
        post "/paymentIntents/create", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("status" => "success")
      end
    end

    context "when params are valid but there are insufficient funds" do
      before do
        allow(RebillOperation).to receive(:call).and_return(double("RebillOperation", insufficient_funds?: true))
      end

      it "returns an insufficient funds response" do
        post "/paymentIntents/create", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq("status" => "insufficient_funds")
      end
    end

    context "when params are invalid" do
      before do
        allow(RebillOperation).to receive(:call).and_raise(RebillOperation::InvalidParams)
      end

      it "returns a failed response" do
        post "/paymentIntents/create", params: invalid_params

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq("status" => "failed")
      end
    end
  end
end
