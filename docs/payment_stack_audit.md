# Payment Stack Audit

## Findings

1. High: confirmed payments are never finalized, so wallet top-ups cannot succeed end-to-end. The webhook path stops at enqueueing a job, and the processor is still a no-op, so `Payment` stays `pending`, `financial_account` is never credited, and `processed_at` is never set on the webhook event.
   References:
   - `app/controllers/webhooks/stripe_controller.rb`
   - `app/jobs/process_payment_webhook_job.rb`
   - `app/services/payments/process_webhook_event.rb`

2. High: YooKassa is exposed as a selectable payment provider, but there is no YooKassa webhook ingestion route/controller and no provider-specific completion flow. Users can start a YooKassa payment, but there is no implemented path for that payment to settle internally.
   References:
   - `app/views/balances/show.html.slim`
   - `app/services/payments/create_top_up.rb`
   - `app/services/payments/gateway/yookassa_strategy.rb`
   - `config/routes.rb`

3. Medium: new wallets still default to `RUB`, which is inconsistent with the multi-currency direction of the payment stack. Any user who gets a wallet lazily via `financial_account!` will receive a RUB account regardless of locale, provider, or intended billing currency. That affects top-ups and auction money flows for users without a pre-created account.
   References:
   - `app/models/user.rb`

4. Medium: legacy `Transaction` still exists in the domain model and remains associated from `User`, even though the active money flow has moved to `LedgerEntry`. That is not causing an active bug right now, but it is a real maintenance risk because future code can accidentally write to the old ledger again.
   References:
   - `app/models/user.rb`
   - `app/models/transaction.rb`

## Open Questions / Assumptions

- The audit assumes both `Stripe` and `YooKassa` top-ups are intended to become production-usable. If only the internal wallet and auction flow was in scope, findings 1 and 2 are expected incompleteness rather than regressions.
- The audit assumes wallet currency should be explicit per user or account, rather than globally defaulting to `RUB`.

## Summary

The wallet and auction hold/capture path is structurally sound and covered well by tests. The main remaining gap is payment completion: top-up creation exists, but confirmed external payments still do not transition into credited internal funds.
