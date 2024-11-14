class PostponedPartialRebillJob
  include Sidekiq::Job

  def perform(amount, subscription_id)
    RebillOperation.call(amount: amount, subscription_id: subscription_id)
  end
end
