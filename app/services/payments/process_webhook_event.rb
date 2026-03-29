module Payments
  class ProcessWebhookEvent
    Result = Struct.new(:success?, :payment_webhook_event, :payment, :error, :ignored?, keyword_init: true)

    def initialize(payment_webhook_event:)
      @payment_webhook_event = payment_webhook_event
    end

    def call
      return success_result(nil, ignored: true) if payment_webhook_event.processed_at.present?

      payment = process_event
      payment_webhook_event.update!(processed_at: Time.current)

      success_result(payment)
    rescue StandardError => e
      Result.new(success?: false, payment_webhook_event: payment_webhook_event, payment: nil, error: e.message, ignored?: false)
    end

    private

    attr_reader :payment_webhook_event

    def process_event
      case payment_webhook_event.provider
      when "stripe"
        process_stripe_event
      when "yookassa"
        process_yookassa_event
      else
        nil
      end
    end

    def process_stripe_event
      payload = payment_webhook_event.payload
      event_type = payment_webhook_event.event_type
      object = payload.fetch("data").fetch("object")
      payment = find_stripe_payment(object)
      return nil unless payment

      case event_type
      when "checkout.session.completed"
        finalize_payment(payment, payload)
      when "checkout.session.expired", "payment_intent.payment_failed"
        fail_payment(payment, payload, status: :failed)
      else
        nil
      end
    end

    def process_yookassa_event
      payload = payment_webhook_event.payload
      event_type = payment_webhook_event.event_type
      object = payload.fetch("object")
      payment = find_yookassa_payment(object)
      return nil unless payment

      case event_type
      when "payment.succeeded"
        finalize_payment(payment, payload)
      when "payment.canceled"
        fail_payment(payment, payload, status: :canceled)
      else
        nil
      end
    end

    def find_stripe_payment(object)
      metadata = object["metadata"] || {}

      Payment.find_by(id: metadata["payment_id"]) ||
        Payment.find_by(provider: :stripe, provider_checkout_session_id: object["id"]) ||
        Payment.find_by(provider: :stripe, provider_payment_id: object["payment_intent"])
    end

    def find_yookassa_payment(object)
      metadata = object["metadata"] || {}

      Payment.find_by(id: metadata["payment_id"]) ||
        Payment.find_by(provider: :yookassa, provider_payment_id: object["id"])
    end

    def finalize_payment(payment, payload)
      update_provider_identifiers!(payment, payload)
      result = FinalizeTopUp.new(payment: payment, payload: payload).call
      raise StandardError, result.error unless result.success?

      result.payment
    end

    def fail_payment(payment, payload, status:)
      update_provider_identifiers!(payment, payload)
      result = FailPayment.new(payment: payment, payload: payload, status: status).call
      raise StandardError, result.error unless result.success?

      result.payment
    end

    def update_provider_identifiers!(payment, payload)
      case payment.provider
      when "stripe"
        object = payload.fetch("data").fetch("object")
        payment.update!(
          provider_checkout_session_id: payment.provider_checkout_session_id.presence || object["id"],
          provider_payment_id: payment.provider_payment_id.presence || object["payment_intent"]
        )
      when "yookassa"
        object = payload.fetch("object")
        payment.update!(
          provider_payment_id: payment.provider_payment_id.presence || object["id"]
        )
      end
    end

    def success_result(payment, ignored: false)
      Result.new(success?: true, payment_webhook_event: payment_webhook_event, payment: payment, error: nil, ignored?: ignored)
    end
  end
end
