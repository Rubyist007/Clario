# Clario test assignment

## Setup

Run `rails db:setup` to setup DB and populate in with 10 subscriptions

## Database

The database has a single table `subscriptions` that has `id`, `status`, `created_at`, and `updated_at` that's minimal setup required for a test assignment

## API

API consists from single endpoint `POST /paymentIntents/create` that accept two parameters
* amount: the amount to charge
* subscription_id: the subscription identifier

Response will be next:
For success case:
Body: `{status: success}`
Status: `200 OK`
For insufficient funds case:
Body: `{status: insufficient_funds}`
Status: `422 Unprocessable Entity`
