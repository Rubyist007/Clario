class RebillValidator
  class << self
    def valid?(amount:, subscription_id:)
      valid_amount?(amount) && valid_subscription_id?(subscription_id)
    end

    private

      def valid_amount?(amount)
        amount.is_a?(Numeric) && amount > 0
      end

      def valid_subscription_id?(subscription_id)
        subscription_id.is_a?(Numeric) && subscription_id > 0 && Subscription.exists?(subscription_id)
      end
  end
end
