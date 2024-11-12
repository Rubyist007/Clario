# Create first 10 active subscription
Subscription.insert_all([{status: :active}] * 10)
