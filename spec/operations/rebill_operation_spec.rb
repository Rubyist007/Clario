require 'rails_helper'

RSpec.describe RebillOperation do
  let(:amount) { 100.0 }
  let(:subscription_id) { 123 }
  let(:rebill_operation) { described_class.new(amount: amount, subscription_id: subscription_id) }

  before do
    allow(Subscription).to receive(:exists?).with(subscription_id).and_return(true)
  end

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

      it 'sets the status to :full_rebill and does not schedule next rebill' do
        expect(rebill_operation).not_to receive(:schedule_next_rebill)
        rebill_operation.call
        expect(rebill_operation.status).to eq(:full_rebill)
      end
    end

    context 'when a later attempt is successful' do
      before do
        allow(BankApiStub).to receive(:charge).and_return("failure", "failure", "success")
      end

      it 'sets the status to :partial_rebill and schedules the next rebill' do
        expect(rebill_operation).to receive(:schedule_next_rebill)
        rebill_operation.call
        expect(rebill_operation.status).to eq(:partial_rebill)
      end
    end

    context 'when all attempts fail' do
      before do
        allow(BankApiStub).to receive(:charge).and_return("failure", "failure", "failure", "failure")
      end

      it 'sets the status to :insufficient_funds and does not schedule next rebill' do
        expect(rebill_operation).not_to receive(:schedule_next_rebill)
        rebill_operation.call
        expect(rebill_operation.status).to eq(:insufficient_funds)
      end
    end
  end

  describe 'private methods' do
    describe '#schedule_next_rebill' do
      it 'schedules the PostponedPartialRebillJob with remaining_to_charge and subscription_id' do
        allow(rebill_operation).to receive(:partial_rebill?).and_return(true)
        allow(rebill_operation).to receive(:remaining_to_charge).and_return(25.0)

        expect(PostponedPartialRebillJob).to receive(:perform_in).with(1.week, 25.0, subscription_id)
        rebill_operation.send(:schedule_next_rebill)
      end
    end

    describe '#remaining_to_charge' do
      before do
        allow(rebill_operation).to receive(:successful_rebill?).and_return(true)
        rebill_operation.send(:finalize_success, 2, 75.0)
      end

      it 'calculates the correct remaining amount' do
        expect(rebill_operation.send(:remaining_to_charge)).to eq(25.0)
      end
    end

    describe 'status-check methods' do
      it 'responds to generated status-check methods' do
        expect(rebill_operation).to respond_to(:pending?, :full_rebill?, :partial_rebill?, :insufficient_funds?)
      end

      it 'returns true for the correct status-check method' do
        rebill_operation.send(:finalize_success, 1, 100.0)
        expect(rebill_operation.full_rebill?).to be true
        expect(rebill_operation.partial_rebill?).to be false
      end
    end

    describe '#successful_rebill?' do
      it 'returns true if the bank response is "success"' do
        allow(BankApiStub).to receive(:charge).and_return("success")
        expect(rebill_operation.send(:successful_rebill?, 100.0)).to be true
      end

      it 'returns false if the bank response is not "success"' do
        allow(BankApiStub).to receive(:charge).and_return("failure")
        expect(rebill_operation.send(:successful_rebill?, 100.0)).to be false
      end
    end

    describe '#finalize_success' do
      before do
        allow(rebill_operation).to receive(:log_rebill_results)
      end

      it 'sets the status to :full_rebill if it succeeds on the first attempt' do
        rebill_operation.send(:finalize_success, 1, 100.0)
        expect(rebill_operation.status).to eq(:full_rebill)
      end

      it 'sets the status to :partial_rebill if it succeeds on a later attempt' do
        rebill_operation.send(:finalize_success, 2, 75.0)
        expect(rebill_operation.status).to eq(:partial_rebill)
      end
    end

    describe '#finalize_failure' do
      before do
        allow(rebill_operation).to receive(:log_rebill_results)
      end

      it 'sets the status to :insufficient_funds' do
        rebill_operation.send(:finalize_failure)
        expect(rebill_operation.status).to eq(:insufficient_funds)
      end
    end

    describe "#validate_params" do
      it "raises an InvalidParams error if parameters are invalid" do
        operation = described_class.new(amount: -10, subscription_id: "invalid_id")

        expect { operation.send(:validate_params) }.to raise_error(RebillOperation::InvalidParams)
      end
    end
  end
end
