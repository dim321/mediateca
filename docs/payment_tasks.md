# Payment Integration Tasks

| Order | Status | Task | Scope | Acceptance Criteria | Dependencies |
|---|---|---|---|---|---|
| 1 | [x] | Add payment dependencies and initializers | `Gemfile`, `config/initializers/*` | `bundle install` succeeds, app boots, Stripe and YooKassa config objects are available, missing credentials fail clearly | None |
| 2 | [x] | Introduce financial schema | `db/migrate`, `db/schema.rb` | Tables `financial_accounts`, `ledger_entries`, `payments`, `payment_webhook_events` exist with indexes and constraints, backfill creates one account per user | 1 |
| 3 | [x] | Add financial domain models | `app/models/*` | `FinancialAccount`, `LedgerEntry`, `Payment`, `PaymentWebhookEvent` load correctly, enums and associations are covered by model specs | 2 |
| 4 | [x] | Build wallet mutation services | `app/services/billing/*` | Credit, hold, release, capture, and balance check work under row locks, ledger entries are append-only, concurrent overspend is prevented | 3 |
| 5 | [x] | Move balance page to new wallet | `BalancesController`, balance views, layout | Balance screen reads from `financial_account`, history uses `ledger_entries`, old instant deposit action is not exposed in UI | 4 |
| 6 | [x] | Add provider strategy layer | `app/services/payments/gateway/*`, resolver | Strategy contract exists, provider selection resolves correctly, external request payloads include metadata and idempotency keys | 5 |
| 7 | [x] | Implement top-up creation flow | `TopUpsController`, routes, `Payments::CreateTopUp` | User can choose Stripe or YooKassa, local `Payment` is created in `pending`, redirect URL is returned and persisted | 6 |
| 8 | [x] | Implement Stripe webhook ingestion | Stripe webhook controller, job, processor | Valid Stripe webhook is accepted, invalid signature returns `400`, raw event is stored exactly once | 7 |
| 9 | [x] | Implement YooKassa webhook ingestion | YooKassa webhook controller, job, processor | YooKassa webhook is accepted, raw event is stored exactly once, duplicate event does not create duplicate side effects | 7 |
| 10 | [x] | Finalize top-up on confirmed webhook | `Payments::FinalizeTopUp`, `Payments::FailPayment` | `Payment` transitions to `succeeded` or `failed`, account is credited exactly once, repeated processing is idempotent | 8, 9 |
| 11 | [ ] | Add reconciliation for stuck payments | reconciliation job and scheduling | Old `pending` and `processing` payments are rechecked against PSP state, mismatches are logged or marked for review | 10 |
| 12 | [x] | Refactor bids to use available funds | `Auctions::BidService`, bids specs | Bid validation uses `financial_account.available_amount_cents`, insufficient funds are enforced on the new model | 4, 10 |
| 13 | [x] | Add hold placement for leading bids | `Auctions::BidService` and helper services | New highest bid creates a hold, one user cannot overspend across multiple auctions | 12 |
| 14 | [x] | Add hold release on outbid | auction helpers and specs | When a bidder is outbid, their hold is released correctly and only once | 13 |
| 15 | [ ] | Refactor auction close to capture held funds | `Auctions::CloseAuctionService` | Closing an auction captures held funds instead of direct deduction, no capture means no broadcast and no sold slot | 14 |
| 16 | [x] | Remove legacy deposit and deduction services | old billing services | Old `DepositService`, `DeductionService`, and old balance checks are removed or reduced to safe wrappers over the new layer | 15 |
| 17 | [ ] | Replace legacy `Transaction` usage | model, factories, specs, balance history | App code no longer depends on legacy `Transaction`, history reads only from `LedgerEntry` | 16 |
| 18 | [x] | Remove `users.balance` | migration, `User`, seeds, factories | `users.balance` column and constraint are removed, new users still get a working wallet, test suite remains green | 17 |

## Suggested Execution Order

1. Complete tasks 1 through 4 before changing any user-facing payment flow.
2. Before enabling real top-ups in any environment, complete tasks 5 through 10.
3. Do not rely on wallet funds in auction settlement until tasks 12 through 15 are complete.
4. Only proceed with tasks 16 through 18 after the new path is stable and fully green.

## Mandatory Test Checklist

| Status | Test Area | Required Coverage |
|---|---|---|
| [ ] | Models | `FinancialAccount`, `LedgerEntry`, `Payment`, `PaymentWebhookEvent`, updated `User` associations and validations |
| [ ] | Billing services | credit, hold, release, capture, balance check, idempotency, row locking, overspend protection |
| [ ] | Payment services | strategy resolver, Stripe strategy, YooKassa strategy, top-up creation, finalize top-up, failure path |
| [ ] | Webhooks | Stripe signature validation, YooKassa event ingestion, duplicate event handling, exact-once crediting |
| [ ] | Requests | top-up creation, balance page, bids flow on available funds, webhook endpoints |
| [ ] | Auctions | hold on bid, release on outbid, capture on close, failure blocks downstream actions |
| [ ] | Jobs | webhook processing job, reconciliation job |
| [ ] | Data migration | legacy `users.balance` backfill into `financial_account`, new-user wallet bootstrap |

## Definition of Done

- [ ] All money mutations go through wallet services and create ledger entries.
- [ ] No balance is credited from a redirect or success page.
- [ ] Webhook processing is idempotent for Stripe and YooKassa.
- [ ] Auctions no longer read or mutate `user.balance`.
- [ ] Legacy `Transaction` and `users.balance` are fully removed.
- [ ] Full automated test suite is green.
