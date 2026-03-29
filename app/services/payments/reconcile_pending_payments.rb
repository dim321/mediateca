module Payments
  class ReconcilePendingPayments
    DEFAULT_BATCH_SIZE = 100
    DEFAULT_OLDER_THAN = 5.minutes

    Result = Struct.new(:scanned_count, :succeeded_count, :failed_count, :updated_count, :error_count, keyword_init: true)

    def initialize(scope: nil, batch_size: DEFAULT_BATCH_SIZE)
      @scope = scope
      @batch_size = batch_size
    end

    def call
      counters = {
        scanned_count: 0,
        succeeded_count: 0,
        failed_count: 0,
        updated_count: 0,
        error_count: 0
      }

      scope.find_each(batch_size: batch_size) do |payment|
        counters[:scanned_count] += 1
        reconcile_payment(payment, counters)
      end

      Result.new(**counters)
    end

    private

    attr_reader :scope, :batch_size

    def scope
      @scope ||= default_scope
    end

    def default_scope
      Payment.where(status: [ :pending, :processing ])
        .where("created_at < ?", DEFAULT_OLDER_THAN.ago)
        .order(:id)
        .limit(DEFAULT_BATCH_SIZE)
    end

    def reconcile_payment(payment, counters)
      response = fetcher_for(payment).fetch(payment)

      if response.terminal_success?
        result = FinalizeTopUp.new(payment: payment, payload: reconciliation_payload(payment, response)).call
        raise StandardError, result.error unless result.success?

        counters[:succeeded_count] += 1
      elsif response.terminal_failure?
        result = FailPayment.new(
          payment: payment,
          payload: reconciliation_payload(payment, response),
          status: response.remote_status,
          failure_reason: response.failure_reason
        ).call
        raise StandardError, result.error unless result.success?

        counters[:failed_count] += 1
      elsif response.non_terminal?
        update_non_terminal_status!(payment, response)
        counters[:updated_count] += 1
      end
    rescue StandardError => e
      Rails.logger.error("Payment reconciliation failed for payment ##{payment.id}: #{e.message}")
      counters[:error_count] += 1
    end

    def update_non_terminal_status!(payment, response)
      target_status = response.remote_status == :requires_action ? :requires_action : :processing
      return if payment.status == target_status.to_s

      payment.update!(
        status: target_status,
        raw_response: payment.raw_response.deep_merge("reconciliation" => response.payload)
      )
    end

    def reconciliation_payload(payment, response)
      {
        "source" => "reconciliation",
        "provider" => payment.provider,
        "event_type" => "reconciliation.#{response.remote_status}",
        "object" => response.payload
      }
    end

    def fetcher_for(payment)
      case payment.provider
      when "stripe"
        Payments::Reconciliation::StripeFetcher.new
      when "yookassa"
        Payments::Reconciliation::YookassaFetcher.new
      else
        raise ArgumentError, "Unsupported payment provider: #{payment.provider}"
      end
    end
  end
end
