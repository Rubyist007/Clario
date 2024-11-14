class RebillOperation
  ATTEMPTS_MULTIPLIER = [1.0, 0.75, 0.5, 0.25].freeze
  STATUSES = [
    PENDING = :pending,
    FULL_REBILL = :full_rebill,
    PARTIAL_REBILL = :partial_rebill,
    INSUFFICIENT_FUNDS = :insufficient_funds,
  ].freeze

  attr_reader :amount, :subscription_id, :status

  def self.call(...)
    new(...).call
  end

  def initialize(amount:, subscription_id:)
    @amount = amount
    @subscription_id = subscription_id
    @status = PENDING
  end

  def call
    try_to_rebill

    status
  end

  private

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

    def finalize_success(attempt_number, charge_amount)
      @status = attempt_number <= 1 ? FULL_REBILL : PARTIAL_REBILL

      log_rebill_results("Rebill for subscription: #{subscription_id} succeeded | Amount: #{charge_amount} | Status: #{status}")
    end

    def finalize_failure
      @status = INSUFFICIENT_FUNDS

      log_rebill_results("Rebill for subscription: #{subscription_id} failed")
    end

    def log_rebill_results(message)
      logger.info(message)
    end

    def logger
      Rails.logger
    end
end
