require 'rails_helper'

RSpec.describe RebillOperation do
  let(:amount) { 100.0 }
  let(:subscription_id) { 123 }
  let(:rebill_operation) { described_class.new(amount: amount, subscription_id: subscription_id) }

  before do
    allow(Subscription).to receive(:exists?).with(subscription_id).and_return(true)

    # Mock Subscription model to return a dummy subscription object
    subscription_mock = double('Subscription', id: subscription_id, inactive!: true)
    allow(Subscription).to receive(:find).with(subscription_id).and_return(subscription_mock)
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

      it 'sets the status to :full_rebill and does not schedule the next rebill' do
        expect(rebill_operation).not_to receive(:schedule_next_rebill)
        rebill_operation.call
        expect(rebill_operation.status).to eq(:full_rebill)
        expect(rebill_operation.charged_amount).to eq(100.0)
      end
    end

    context 'when the second attempt is successful (partial rebill)' do
      before do
        allow(BankApiStub).to receive(:charge).and_return("failure", "success")
      end

      it 'sets the status to :partial_rebill and schedules the next rebill' do
        expect(rebill_operation).to receive(:schedule_next_rebill)
        rebill_operation.call
        expect(rebill_operation.status).to eq(:partial_rebill)
        expect(rebill_operation.charged_amount).to eq(75.0) # 75% of the original amount
      end
    end

    context 'when all attempts fail (insufficient funds)' do
      before do
        allow(BankApiStub).to receive(:charge).and_return("failure", "failure", "failure", "failure")
      end

      it 'sets the status to :insufficient_funds and does not schedule the next rebill' do
        expect(rebill_operation).not_to receive(:schedule_next_rebill)
        rebill_operation.call
        expect(rebill_operation.status).to eq(:insufficient_funds)
      end

      it 'calls inactive! on the subscription' do
        subscription_double = double('Subscription', inactive!: true)
        allow(rebill_operation).to receive(:subscription).and_return(subscription_double)

        rebill_operation.call
        expect(subscription_double).to have_received(:inactive!)
      end
    end

    context 'when the amount is invalid' do
      it 'raises an InvalidParams exception' do
        invalid_operation = described_class.new(amount: -10, subscription_id: subscription_id)
        expect { invalid_operation.call }.to raise_error(RebillOperation::InvalidParams)
      end
    end
  end

  describe '#schedule_next_rebill' do
    it 'schedules the PostponedPartialRebillJob with the correct parameters' do
      allow(rebill_operation).to receive(:partial_rebill?).and_return(true)
      allow(rebill_operation).to receive(:remaining_to_charge).and_return(25.0)

      expect(PostponedPartialRebillJob).to receive(:perform_in).with(1.week, 25.0, subscription_id)
      rebill_operation.send(:schedule_next_rebill)
    end
  end

  describe '#remaining_to_charge' do
    context 'when the rebill is successful on the first attempt' do
      before do
        rebill_operation.send(:finalize_success, 1, 100.0)
      end

      it 'calculates the remaining charge correctly' do
        expect(rebill_operation.send(:remaining_to_charge)).to eq(0.0)
      end
    end

    context 'when the rebill is partial' do
      before do
        rebill_operation.send(:finalize_success, 2, 75.0)
      end

      it 'calculates the remaining charge correctly' do
        expect(rebill_operation.send(:remaining_to_charge)).to eq(25.0)
      end
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

    it 'sets the status to :insufficient_funds' do
      rebill_operation.send(:finalize_failure)
      expect(rebill_operation.status).to eq(:insufficient_funds)
    end
  end

  describe '#validate_params' do
    it 'raises an InvalidParams error if parameters are invalid' do
      invalid_operation = described_class.new(amount: -10, subscription_id: "invalid_id")
      expect { invalid_operation.send(:validate_params) }.to raise_error(RebillOperation::InvalidParams)
    end
  end
end
