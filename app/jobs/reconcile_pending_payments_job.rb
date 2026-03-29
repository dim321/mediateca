class ReconcilePendingPaymentsJob < ApplicationJob
  queue_as :payments

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(batch_size: Payments::ReconcilePendingPayments::DEFAULT_BATCH_SIZE)
    Payments::ReconcilePendingPayments.new(batch_size: batch_size).call
  end
end
