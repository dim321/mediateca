# Payment Integration Technical Plan

## Architecture

The implementation should be split into 4 stages to avoid breaking the current auction and balance flows. The target is to separate external payment processing, internal wallet state, and immutable accounting history.

Target model:

- `User` is no longer the financial model.
- `FinancialAccount` stores the current wallet state for a user.
- `LedgerEntry` stores immutable balance movements.
- `Payment` stores the lifecycle of an external Stripe or YooKassa payment.
- `PaymentWebhookEvent` stores incoming webhook events and prevents duplicate processing.
- Strategy classes `StripeStrategy` and `YookassaStrategy` encapsulate PSP-specific integration.

Balance recommendation:

- Keep `users.balance` only as a temporary legacy attribute during migration.
- Make `financial_accounts.available_amount_cents` and `financial_accounts.held_amount_cents` the new source of truth.
- Remove `users.balance` after the migration is complete.

## Plan By Files

### 1. Base dependencies and configuration

Update `/home/dim/Projects/MyPets/mediateca/Gemfile`

- Add `stripe`
- Add an HTTP client for YooKassa, either `faraday` or `httpx`
- Add `money-rails` only if you want centralized money handling; it is optional

Add initializers:

- `/home/dim/Projects/MyPets/mediateca/config/initializers/stripe.rb`
- `/home/dim/Projects/MyPets/mediateca/config/initializers/yookassa.rb`

Add credentials or env keys:

- `stripe_secret_key`
- `stripe_webhook_secret`
- `yookassa_shop_id`
- `yookassa_secret_key`

### 2. New migrations

Add migration `create_financial_accounts`

- `user:references`
- `currency:string, null: false, default: "RUB"`
- `available_amount_cents:bigint, null: false, default: 0`
- `held_amount_cents:bigint, null: false, default: 0`
- `status:integer, null: false, default: 0`
- unique index on `user_id`

Add migration `create_ledger_entries`

- `financial_account:references`
- `entry_type:integer, null: false`
- `amount_cents:bigint, null: false`
- `currency:string, null: false`
- `balance_after_cents:bigint, null: false`
- `held_after_cents:bigint, null: false`
- `description:string, null: false`
- `reference_type/reference_id`
- `payment_id`
- `idempotency_key:string`
- `metadata:jsonb, default: {}`
- indexes for `financial_account_id, created_at`, `payment_id`, `idempotency_key`, `reference_type/reference_id`

Add migration `create_payments`

- `user:references`
- `financial_account:references`
- `provider:integer, null: false`
- `operation_type:integer, null: false`
- `status:integer, null: false`
- `amount_cents:bigint, null: false`
- `currency:string, null: false`
- `provider_payment_id:string`
- `provider_customer_id:string`
- `provider_checkout_session_id:string`
- `idempotency_key:string, null: false`
- `confirmation_url:text`
- `return_url:text`
- `failure_reason:string`
- `paid_at:datetime`
- `failed_at:datetime`
- `metadata:jsonb, default: {}`
- `raw_response:jsonb, default: {}`
- indexes for `provider/provider_payment_id`, `idempotency_key`, `status`

Add migration `create_payment_webhook_events`

- `provider:integer`
- `event_id:string, null: false`
- `event_type:string, null: false`
- `payload:jsonb, null: false, default: {}`
- `processed_at:datetime`
- unique index on `provider, event_id`

Add data migration:

- create `FinancialAccount` for all users
- copy `users.balance` into `financial_accounts.available_amount_cents`

Add a later cleanup migration:

- remove `users.balance`
- remove check constraint `positive_balance`

Resolve current `transactions` table separately:

- preferred path: create `ledger_entries` as a new table, keep the old `transactions` table temporarily for reading
- later perform backfill and remove the old model

### 3. New models

Add `/home/dim/Projects/MyPets/mediateca/app/models/financial_account.rb`

- `belongs_to :user`
- `has_many :ledger_entries`
- `has_many :payments`
- methods `available_amount`, `held_amount`, `total_amount`
- use row locking with `with_lock`

Add `/home/dim/Projects/MyPets/mediateca/app/models/ledger_entry.rb`

- append-only, disallow update and destroy
- enum `entry_type`: `deposit_settled`, `hold`, `release`, `capture`, `refund`, `adjustment`

Add `/home/dim/Projects/MyPets/mediateca/app/models/payment.rb`

- enum `provider`: `stripe`, `yookassa`
- enum `operation_type`: `top_up`, `refund`
- enum `status`: `pending`, `requires_action`, `processing`, `succeeded`, `failed`, `canceled`

Add `/home/dim/Projects/MyPets/mediateca/app/models/payment_webhook_event.rb`

Update `/home/dim/Projects/MyPets/mediateca/app/models/user.rb`

- add `has_one :financial_account`
- add `has_many :payments`
- remove domain logic that depends on the `balance` field and move it into `financial_account`
- optionally keep a temporary `balance` proxy method to `financial_account.available_amount_cents` for a smooth migration

Mark `/home/dim/Projects/MyPets/mediateca/app/models/transaction.rb` as legacy and phase it out, then remove it later.

### 4. Payments layer and Strategy pattern

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway/base.rb`

- contract methods: `create_top_up(payment:)`, `parse_webhook(request:)`, `verify_webhook!(request:)`

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway/stripe_strategy.rb`

- create Stripe Checkout Session
- include metadata: `payment_id`, `user_id`
- use idempotency key on create

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway/yookassa_strategy.rb`

- create YooKassa `payment` with redirect confirmation
- require `Idempotence-Key`
- keep internal `payment_id` in metadata or description

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway_resolver.rb`

- selects strategy by `provider`

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/create_top_up.rb`

- creates local `Payment`
- calls the strategy
- stores `provider_payment_id` and `confirmation_url`

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/finalize_top_up.rb`

- called only from webhook or job
- idempotently marks `Payment` as `succeeded`
- creates `LedgerEntry`
- increments `financial_account.available_amount_cents`

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/fail_payment.rb`

Add `/home/dim/Projects/MyPets/mediateca/app/services/payments/process_webhook_event.rb`

### 5. Internal wallet and ledger layer

Add `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_credit.rb`

Add `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_hold.rb`

Add `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_release.rb`

Add `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_capture.rb`

Add `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_balance_check.rb`

Current services:

- `/home/dim/Projects/MyPets/mediateca/app/services/billing/deposit_service.rb` should be replaced with a thin wrapper over `Payments::CreateTopUp` or removed
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/deduction_service.rb` should be replaced by `AccountCapture`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/balance_check_service.rb` should be rewritten to use `FinancialAccount`

### 6. Controllers and routes

Update `/home/dim/Projects/MyPets/mediateca/config/routes.rb`

- replace `post :deposit` with:
  - `post :top_ups`
  - `get :success`
  - `get :cancel`
- add webhook namespace:
  - `post "/webhooks/stripe", to: "webhooks/stripe#create"`
  - `post "/webhooks/yookassa", to: "webhooks/yookassa#create"`

Update `/home/dim/Projects/MyPets/mediateca/app/controllers/balances_controller.rb`

- `show` reads balance and history from `financial_account`
- remove `deposit`

Add `/home/dim/Projects/MyPets/mediateca/app/controllers/top_ups_controller.rb`

- accepts amount and provider
- creates local `Payment`
- redirects to `confirmation_url`

Add `/home/dim/Projects/MyPets/mediateca/app/controllers/webhooks/stripe_controller.rb`

- verify `Stripe-Signature`
- return `200` quickly
- enqueue job

Add `/home/dim/Projects/MyPets/mediateca/app/controllers/webhooks/yookassa_controller.rb`

- accept notification
- persist `PaymentWebhookEvent`
- enqueue job

### 7. Jobs

Add `/home/dim/Projects/MyPets/mediateca/app/jobs/process_payment_webhook_job.rb`

- loads `PaymentWebhookEvent`
- calls `Payments::ProcessWebhookEvent`

Add `/home/dim/Projects/MyPets/mediateca/app/jobs/reconcile_pending_payments_job.rb`

- periodically checks stuck `pending` and `processing` payments
- fetches latest status from Stripe or YooKassa

### 8. Auctions

Update `/home/dim/Projects/MyPets/mediateca/app/services/auctions/bid_service.rb`

- remove checks against `user.balance`
- check `financial_account.available_amount_cents`
- when a user becomes highest bidder, create a hold for the bid amount or the delta
- when outbid, release the previous highest bidder hold

Update `/home/dim/Projects/MyPets/mediateca/app/services/auctions/close_auction_service.rb`

- stop direct deductions
- call `AccountCapture`
- if capture fails, do not create `scheduled_broadcast` and do not mark the slot as `sold`

Optional support services:

- `/home/dim/Projects/MyPets/mediateca/app/services/auctions/release_outbid_hold.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/auctions/capture_winner_hold.rb`

### 9. UI

Update `/home/dim/Projects/MyPets/mediateca/app/views/balances/show.html.slim`

- add payment provider selection: `stripe` or `yookassa`
- the top-up form should create a top-up request, not instantly credit the balance
- history should be loaded from `ledger_entries`
- show external payment statuses separately

Update `/home/dim/Projects/MyPets/mediateca/app/views/layouts/application.html.slim`

- render `current_user.financial_account.available_amount`

Update `/home/dim/Projects/MyPets/mediateca/app/views/auctions/show.html.slim`

- display available balance and optionally held amount

### 10. Seeds and factories

Update `/home/dim/Projects/MyPets/mediateca/db/seeds.rb`

- create `financial_account` instead of assigning `user.balance`

Update or add factories:

- `/home/dim/Projects/MyPets/mediateca/spec/factories/users.rb`
- `financial_account`
- `ledger_entry`
- `payment`
- `payment_webhook_event`

Move `/home/dim/Projects/MyPets/mediateca/spec/factories/transactions.rb` to legacy usage or remove it after migration.

## Required Tests

### 1. Models

Add `/home/dim/Projects/MyPets/mediateca/spec/models/financial_account_spec.rb`

- validations
- unique account per user
- non-negative amounts

Add `/home/dim/Projects/MyPets/mediateca/spec/models/ledger_entry_spec.rb`

- append-only behavior
- enum values
- correct money signs and persisted state

Add `/home/dim/Projects/MyPets/mediateca/spec/models/payment_spec.rb`

- statuses
- providers
- idempotency key uniqueness behavior

Add `/home/dim/Projects/MyPets/mediateca/spec/models/payment_webhook_event_spec.rb`

- deduplication on `provider + event_id`

Update `/home/dim/Projects/MyPets/mediateca/spec/models/user_spec.rb`

- add `has_one :financial_account`
- remove tests that depend on `balance`

### 2. Billing services

Add `/home/dim/Projects/MyPets/mediateca/spec/services/billing/account_credit_spec.rb`

- credits increase `available_amount_cents`
- creates ledger entry
- idempotent by key

Add `/home/dim/Projects/MyPets/mediateca/spec/services/billing/account_hold_spec.rb`

- hold decreases available and increases held
- insufficient funds failure
- race-condition safety with account locking

Add `/home/dim/Projects/MyPets/mediateca/spec/services/billing/account_release_spec.rb`

Add `/home/dim/Projects/MyPets/mediateca/spec/services/billing/account_capture_spec.rb`

Add `/home/dim/Projects/MyPets/mediateca/spec/services/billing/account_balance_check_spec.rb`

### 3. Payment services

Add `/home/dim/Projects/MyPets/mediateca/spec/services/payments/create_top_up_spec.rb`

- creates `Payment`
- calls the correct strategy
- stores `confirmation_url`

Add `/home/dim/Projects/MyPets/mediateca/spec/services/payments/finalize_top_up_spec.rb`

- marks `Payment` as `succeeded`
- credits the wallet exactly once
- repeated webhook processing does not create duplicates

Add `/home/dim/Projects/MyPets/mediateca/spec/services/payments/process_webhook_event_spec.rb`

- Stripe `checkout.session.completed` or `payment_intent.succeeded`
- YooKassa `payment.succeeded`
- irrelevant events are ignored

Add `/home/dim/Projects/MyPets/mediateca/spec/services/payments/gateway/stripe_strategy_spec.rb`

- create payload contains metadata and idempotency handling

Add `/home/dim/Projects/MyPets/mediateca/spec/services/payments/gateway/yookassa_strategy_spec.rb`

- create payload contains `Idempotence-Key`
- correct `confirmation.return_url`

### 4. Webhooks and request specs

Add `/home/dim/Projects/MyPets/mediateca/spec/requests/webhooks/stripe_spec.rb`

- valid signature
- invalid signature returns `400`
- duplicate event does not re-credit the account

Add `/home/dim/Projects/MyPets/mediateca/spec/requests/webhooks/yookassa_spec.rb`

- `payment.succeeded`
- duplicate notification ignored

Add `/home/dim/Projects/MyPets/mediateca/spec/requests/top_ups_spec.rb`

- create Stripe top-up
- create YooKassa top-up
- invalid amount and provider

### 5. Auctions

Update `/home/dim/Projects/MyPets/mediateca/spec/services/auctions/bid_service_spec.rb`

- bid creates hold
- outbid releases old hold
- insufficient available funds

Update `/home/dim/Projects/MyPets/mediateca/spec/services/auctions/close_auction_service_spec.rb`

- winner hold captured
- broadcast created only after successful capture
- failed capture does not sell the slot

Update `/home/dim/Projects/MyPets/mediateca/spec/requests/bids_spec.rb`

- scenarios based on available funds instead of `user.balance`

### 6. Balance UI and request coverage

Update `/home/dim/Projects/MyPets/mediateca/spec/requests/balances_spec.rb`

- `GET /balance` renders data from `financial_account`
- history shows `ledger_entries`
- remove old `POST /balance/deposit`

Add a system test:

- `/home/dim/Projects/MyPets/mediateca/test/system/top_up_with_provider_selection_test.rb`
- user selects Stripe or YooKassa and is redirected into the payment flow

### 7. Migrations and data integrity

Add migration coverage or smoke-level checks for:

- user with legacy balance is backfilled into `financial_account`
- webhook event uniqueness is enforced
- account locking prevents concurrent overspending

## Implementation Order

1. Add tables `financial_accounts`, `payments`, `payment_webhook_events`, `ledger_entries`.
2. Add models and wallet or ledger services.
3. Move the balance UI to `financial_account`.
4. Implement the payment strategy layer and top-up flow.
5. Implement webhook processing and reconciliation.
6. Move auctions from direct deduction to hold, release, and capture.
7. Remove legacy `users.balance` and old `Transaction`.

## Critical Implementation Rules

- Credit wallet balances only after webhook-confirmed `succeeded`.
- Use idempotency keys on every external payment create call.
- Persist every raw webhook event before processing it.
- Change balances only through append-only ledger writes.
- Perform wallet mutations under account row locking.
- Never treat `return_url` as a successful payment signal.
