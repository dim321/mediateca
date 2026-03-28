# Payment Implementation Backlog

## PR 1. Dependencies and configuration scaffold

Goal: prepare the project for payment integration without changing domain logic.

Files:

- `/home/dim/Projects/MyPets/mediateca/Gemfile`
- `/home/dim/Projects/MyPets/mediateca/config/initializers/stripe.rb`
- `/home/dim/Projects/MyPets/mediateca/config/initializers/yookassa.rb`
- deployment or README docs if needed

Tasks:

- add `stripe`
- add an HTTP client for YooKassa
- add config for secrets and base settings
- define one env or credentials format

Tests:

- initializer load smoke spec
- `rails runner` loads initializers without errors

Risk:

- low

Dependencies:

- none

## PR 2. New financial database schema

Goal: add new entities without breaking old code.

Files:

- new migrations in `/home/dim/Projects/MyPets/mediateca/db/migrate`
- `/home/dim/Projects/MyPets/mediateca/db/schema.rb`

Tasks:

- create `financial_accounts`
- create `ledger_entries`
- create `payments`
- create `payment_webhook_events`
- add indexes, unique constraints, and non-negative constraints
- backfill from legacy `users.balance` into `financial_accounts`

Tests:

- migration smoke test
- model specs for constraints
- backfill spec for a legacy user

Risk:

- medium

Dependencies:

- PR 1

## PR 3. Financial models

Goal: introduce the new domain layer without switching business logic yet.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/models/financial_account.rb`
- `/home/dim/Projects/MyPets/mediateca/app/models/ledger_entry.rb`
- `/home/dim/Projects/MyPets/mediateca/app/models/payment.rb`
- `/home/dim/Projects/MyPets/mediateca/app/models/payment_webhook_event.rb`
- `/home/dim/Projects/MyPets/mediateca/app/models/user.rb`

Tasks:

- add associations
- add enum and status contracts
- implement append-only behavior for `LedgerEntry`
- keep `users.balance` as legacy for now
- add a safe account accessor on `User`

Tests:

- `spec/models/financial_account_spec.rb`
- `spec/models/ledger_entry_spec.rb`
- `spec/models/payment_spec.rb`
- `spec/models/payment_webhook_event_spec.rb`
- update `spec/models/user_spec.rb`

Risk:

- low

Dependencies:

- PR 2

## PR 4. Wallet and ledger services

Goal: make safe balance mutations on the new layer.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_credit.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_hold.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_release.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_capture.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/account_balance_check.rb`

Tasks:

- run all mutations inside `financial_account.with_lock`
- use `LedgerEntry` as the only mutation journal
- add internal idempotency where needed
- enforce `available >= 0` and `held >= 0`

Tests:

- `spec/services/billing/account_credit_spec.rb`
- `spec/services/billing/account_hold_spec.rb`
- `spec/services/billing/account_release_spec.rb`
- `spec/services/billing/account_capture_spec.rb`
- `spec/services/billing/account_balance_check_spec.rb`
- concurrency spec for double spending

Risk:

- high

Dependencies:

- PR 3

## PR 5. Balance UI on the new wallet

Goal: move the UI to the new source of truth while keeping top-up disabled or transitional.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/controllers/balances_controller.rb`
- `/home/dim/Projects/MyPets/mediateca/app/views/balances/show.html.slim`
- `/home/dim/Projects/MyPets/mediateca/app/views/layouts/application.html.slim`
- `/home/dim/Projects/MyPets/mediateca/spec/requests/balances_spec.rb`

Tasks:

- read balance from `financial_account`
- render history from `ledger_entries`
- remove or disable the old instant deposit action in the UI

Tests:

- update balance request specs
- view or request coverage for empty and populated history

Risk:

- medium

Dependencies:

- PR 4

## PR 6. Strategy layer and top-up creation

Goal: create Stripe or YooKassa payments, but do not settle funds yet.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway/base.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway/stripe_strategy.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway/yookassa_strategy.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/gateway_resolver.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/create_top_up.rb`
- `/home/dim/Projects/MyPets/mediateca/app/controllers/top_ups_controller.rb`
- `/home/dim/Projects/MyPets/mediateca/config/routes.rb`

Tasks:

- create local `Payment(status: pending)`
- resolve strategy by provider
- Stripe: create Checkout Session
- YooKassa: create redirect payment
- store `provider_payment_id`, `confirmation_url`, and `idempotency_key`
- add provider selection in the UI

Tests:

- `spec/services/payments/create_top_up_spec.rb`
- `spec/services/payments/gateway/stripe_strategy_spec.rb`
- `spec/services/payments/gateway/yookassa_strategy_spec.rb`
- `spec/requests/top_ups_spec.rb`

Risk:

- medium

Dependencies:

- PR 5

## PR 7. Webhooks and asynchronous payment completion

Goal: safely confirm payments and credit funds.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/controllers/webhooks/stripe_controller.rb`
- `/home/dim/Projects/MyPets/mediateca/app/controllers/webhooks/yookassa_controller.rb`
- `/home/dim/Projects/MyPets/mediateca/app/jobs/process_payment_webhook_job.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/process_webhook_event.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/finalize_top_up.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/payments/fail_payment.rb`

Tasks:

- validate Stripe signatures
- persist every raw webhook as `PaymentWebhookEvent`
- deduplicate webhook events
- transition `Payment` into `succeeded` or `failed`
- credit wallet only from webhook processing
- use return URLs only for UX

Tests:

- `spec/requests/webhooks/stripe_spec.rb`
- `spec/requests/webhooks/yookassa_spec.rb`
- `spec/services/payments/process_webhook_event_spec.rb`
- `spec/services/payments/finalize_top_up_spec.rb`
- duplicate webhook idempotency spec

Risk:

- high

Dependencies:

- PR 6

## PR 8. Reconciliation and stuck payment support

Goal: cover operational gaps between PSP state and local DB state.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/jobs/reconcile_pending_payments_job.rb`
- `/home/dim/Projects/MyPets/mediateca/config/recurring.yml`

Tasks:

- periodically scan `pending` and `processing` payments
- fetch latest PSP status
- log or mark mismatches for operator review
- add useful scopes for support or admin use

Tests:

- reconciliation job spec
- service spec for stuck payments

Risk:

- medium

Dependencies:

- PR 7

## PR 9. Auctions on hold and release

Goal: eliminate overspending across parallel bids.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/services/auctions/bid_service.rb`
- optional helper services under `/home/dim/Projects/MyPets/mediateca/app/services/auctions`
- `/home/dim/Projects/MyPets/mediateca/spec/services/auctions/bid_service_spec.rb`
- `/home/dim/Projects/MyPets/mediateca/spec/requests/bids_spec.rb`

Tasks:

- stop using `user.balance`
- use `financial_account.available_amount_cents`
- place a hold for the current leading bid
- release hold for the previously highest bidder

Tests:

- insufficient available funds
- outbid releases previous hold
- concurrent bids remain consistent
- one user cannot overspend across multiple auctions

Risk:

- high

Dependencies:

- PR 4
- PR 7

## PR 10. Auction close on capture

Goal: finalize auction money flow correctly.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/services/auctions/close_auction_service.rb`
- optional capture helper services
- `/home/dim/Projects/MyPets/mediateca/spec/services/auctions/close_auction_service_spec.rb`

Tasks:

- replace direct deduction with `AccountCapture`
- block `scheduled_broadcast` creation if capture fails
- block slot sale if capture fails
- handle no-winner cases explicitly

Tests:

- happy path capture
- failed capture blocks downstream actions
- already closed auction
- idempotent repeated close

Risk:

- high

Dependencies:

- PR 9

## PR 11. Remove legacy billing code

Goal: remove the old financial layer and ambiguous naming.

Files:

- `/home/dim/Projects/MyPets/mediateca/app/services/billing/deposit_service.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/deduction_service.rb`
- `/home/dim/Projects/MyPets/mediateca/app/services/billing/balance_check_service.rb`
- `/home/dim/Projects/MyPets/mediateca/app/models/transaction.rb`
- `/home/dim/Projects/MyPets/mediateca/spec/factories/transactions.rb`

Tasks:

- delete legacy services or convert them into wrappers over the new layer
- rename references from `Transaction` to `LedgerEntry`
- remove old factories and specs

Tests:

- full green suite
- search check that old `Transaction` is no longer used in app code

Risk:

- medium

Dependencies:

- PR 10

## PR 12. Remove `users.balance`

Goal: complete the migration and remove the legacy source of truth.

Files:

- cleanup migration in `/home/dim/Projects/MyPets/mediateca/db/migrate`
- `/home/dim/Projects/MyPets/mediateca/app/models/user.rb`
- `/home/dim/Projects/MyPets/mediateca/db/seeds.rb`
- remaining specs and views

Tasks:

- drop `users.balance`
- remove the DB check constraint
- remove compatibility methods
- move seeds and factories fully to `financial_account`

Tests:

- schema and model specs
- request specs for balance, auctions, and top-ups
- smoke test for new user account bootstrap

Risk:

- high

Dependencies:

- PR 11

## Minimum production-safe scope

- PR 1 through PR 8 for top-up support
- PR 9 and PR 10 are mandatory if auctions rely on user funds
- PR 11 and PR 12 can follow after stabilization, but should not be deferred too long

## Critical checkpoints

- After PR 4, the new wallet layer must be fully covered with isolated tests.
- After PR 7, top-up must work end to end with webhook-confirmed crediting.
- After PR 10, auctions must no longer depend on `user.balance`.
- After PR 12, the system must have a single source of truth for money.
