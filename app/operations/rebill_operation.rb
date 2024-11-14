class RebillOperation
  class InvalidParams < StandardError; end

  ATTEMPTS_MULTIPLIER = [1.0, 0.75, 0.5, 0.25].freeze
  STATUSES = [
    PENDING = :pending,
    FULL_REBILL = :full_rebill,
    PARTIAL_REBILL = :partial_rebill,
    INSUFFICIENT_FUNDS = :insufficient_funds,
  ].freeze

  attr_reader :amount, :subscription_id, :status, :charged_amount

  def self.call(...)
    new(...).call
  end

  def initialize(amount:, subscription_id:)
    @amount = amount
    @subscription_id = subscription_id
    @status = PENDING
  end

  # Generate methods like pending?, full_rebill?, etc.
  STATUSES.each do |posible_status|
    define_method("#{posible_status}?") do
      status == posible_status
    end
  end

  def call
    validate_params

    try_to_rebill
    schedule_next_rebill if partial_rebill?

    self
  end

  private

    def validate_params
      raise InvalidParams unless params_valid?
    end

    def params_valid?
      RebillValidator.valid?(amount: amount, subscription_id: subscription_id)
    end

    def schedule_next_rebill
      PostponedPartialRebillJob.perform_in(1.week, remaining_to_charge, subscription_id)
    end

    def try_to_rebill
      ATTEMPTS_MULTIPLIER.each.with_index(1) do |attempt_multiplier, attempt_number|
        charge_amount = amount * attempt_multiplier

        return finalize_success(attempt_number, charge_amount) if successful_rebill?(charge_amount)
      end

      finalize_failure
    end

    def successful_rebill?(charge_amount)
      BankApiStub.charge(charge_amount) == "success"
    end

    def finalize_success(attempt_number, charged_amount)
      @status = attempt_number <= 1 ? FULL_REBILL : PARTIAL_REBILL
      @charged_amount = charged_amount

      log_rebill_results("Rebill for subscription: #{subscription_id} succeeded | Amount: #{charged_amount} | Status: #{status}")
    end

    def remaining_to_charge
      amount - charged_amount
    end

    def finalize_failure
      @status = INSUFFICIENT_FUNDS

      subscription.inactive!
      log_rebill_results("Rebill for subscription: #{subscription_id} failed")
    end

    def subscription
      @subscription ||= Subscription.find(subscription_id)
    end

    def log_rebill_results(message)
      logger.info(message)
    end

    def logger
      Rails.logger
    end
end
