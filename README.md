# Clario Test Assignment

The file with the test assignment description is linked below.

[Ruby Billing Task (1) (1) (1) (1) (1).pdf](https://github.com/user-attachments/files/17773782/Ruby.Billing.Task.1.1.1.1.1.pdf)

 Here you may also find the additional clarifications for this task.

<details>
<summary>First small qlarification</summary>

```
Потрібно замінити A maximum of 4 attempts is allowed for each rebill.
на
A maximum of 4 attempts is allowed for each rebill after success payment.
```

</details>

<details>
<summary>Question 1 and Answer</summary>

Question:
```
У випадку Partial Rebill коли ми запланували наступну транзакцію через тиждень, там протрібно просто ще 1 раз спробувати стягнути залишкову суму і все, ніякої додаткової логіки не потрібно, чи потрібно фоловити логіку з Main Rebilling Logiс?
А також що має відбуватись якщо та транзакція через тиждень також не пройшла?
```

Answer:
```
У випадку Partial Rebill коли ми запланували наступну транзакцію через тиждень, там потрібно просто ще 1 раз спробувати стягнути залишкову суму і все, ніякої додаткової логіки не потрібно, чи потрібно фоловити логіку з Main Rebilling Logiс?
Так само по каскаду декілька спроб
А також що має відбуватись якщо та транзакція через тиждень також не пройшла?
то має бути так само декілька спроб
тобто маємо хочаб 25% зчарджити і продовжити підписку на тиждень
```

</details>

<details>
<summary>Question 2 and Answer</summary>

Question:
```
"A maximum of 4 attempts is allowed for each rebill after success payment."
Під 4 attempts тут мається на увазі спроба зачарджити з банку (100%, 75%, 50%, 25%) чи щось інше?
І що має відбуватись якщо у нас не буде successul payment, просто одразу відповідати на повторний запит "insufficient_funds" чи "failed"?
```

Answer:
```
"A maximum of 4 attempts is allowed for each rebill after success payment."
Під 4 attempts тут мається на увазі спроба зачарджити з банку (100%, 75%, 50%, 25%) чи щось інше?
Так, спробувати чарджити на меншу суму
І що має відбуватись якщо у нас не буде successul payment, просто одразу відповідати на повторний запит "insufficient_funds" чи "failed"?
якщо після 4-х спроб провал, то оплата вважається не успішною і підписка має перейти в статус не активної
```

</details>

## Setup

Run `rails db:setup` to setup DB and populate in with 10 subscriptions

Run `bundle exec rails s` to start Rails

Run `redis-server` to start Redis

Run `bundle exec sidekiq` to start Sidekiq

## Database

The database has a single table `subscriptions` that has `id`, `status`, `created_at`, and `updated_at`. That's minimal setup required for a test assignment completion.

## API

API consists of a single endpoint `POST /paymentIntents/create` that accepts two parameters
* amount: the amount to charge
* subscription_id: the subscription identifier

Response will be the following:

For a success case:

Body: `{status: success}`

Status: `200 OK`

---

For the 'insufficient funds' case:

Body: `{status: insufficient_funds}`

Status: `422 Unprocessable Entity`

---

For invalid params case:

Body: `{status: failed}`

Status: `400 Bad Request`


## Tests

To run tests, run next command `bundle exec rspec --format doc`

Example of curl request for testing:
```
curl -X POST http://127.0.0.1:3000/paymentIntents/create \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "subscription_id": 1}'
```

Response should look like this:
```
{"status":"insufficient_funds"}
```

## My extra comment

In general I wanted to implement more functionalities in scope of this assigment, like better validations etc. but I hope that would be enough in order to avoid making this test assigment too big and such things weren't mentioned in the task itself

There is also one thing that I see in the logic, that seems to me a little controversial, let me give an example:
* We had first rebil
* We charged 50%
* Next week we charged 25% of that 50%
* etc.

As a result, we could be charging a very small amount of money for a long time. I agree that this is the edge case, but it still a thing to mention, based on the task logic.
For production I believe there should be more extended logic and such an assumption is ok just for a test assignment purposes.
