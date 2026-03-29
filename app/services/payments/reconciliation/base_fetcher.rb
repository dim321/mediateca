module Payments
  module Reconciliation
    class BaseFetcher
      Response = Struct.new(:remote_status, :payload, :failure_reason, keyword_init: true) do
        def terminal_success?
          remote_status == :succeeded
        end

        def terminal_failure?
          %i[failed canceled].include?(remote_status)
        end

        def non_terminal?
          %i[pending processing requires_action].include?(remote_status)
        end
      end

      def fetch(_payment)
        raise NotImplementedError
      end
    end
  end
end
