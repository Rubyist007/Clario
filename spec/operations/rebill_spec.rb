require 'rails_helper'

RSpec.describe RebillOperation do
  let(:amount) { 100.0 }
  let(:subscription_id) { 123 }
  let(:rebill_operation) { described_class.new(amount: amount, subscription_id: subscription_id) }

  describe '.call' do
    it 'creates a new instance and calls the #call method' do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.call(amount: amount, subscription_id: subscription_id)
    end
  end

  describe '#call' do
    context 'when the first attempt is successful' do
      before do
        allow(BankApiStub).to receive(:charge).with(100.0).and_return("success")
      end

      it 'sets the status to :full_rebill' do
        rebill_operation.call
        expect(rebill_operation.status).to eq(RebillOperation::FULL_REBILL)
      end
    end

    context 'when a later attempt is successful' do
      before do
        allow(BankApiStub).to receive(:charge).and_return("insufficient funds", "success")
      end

      it 'sets the status to :partial_rebill' do
        rebill_operation.call
        expect(rebill_operation.status).to eq(RebillOperation::PARTIAL_REBILL)
      end
    end

    context 'when all attempts fail' do
      before do
        allow(BankApiStub).to receive(:charge).and_return("insufficient funds")
      end

      it 'sets the status to :insufficient_funds' do
        rebill_operation.call
        expect(rebill_operation.status).to eq(:insufficient_funds)
      end
    end
  end
end
