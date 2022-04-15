# frozen_string_literal: true

gem 'sentry-ruby'

module Griffin
  module Interceptors
    module Server
      class SentryInterceptor < GRPC::ServerInterceptor
        def request_response(call: nil, **)
          yield
        rescue => e
          raise e if e.is_a?(GRPC::BadStatus)

          GRPC.logger.error("Internal server error: #{e.message}")

          Sentry.with_scope do |scope|
            if call.metadata['x-request-id']
              scope.set_tags(request_id: call.metadata['x-request-id'])
            end

            Sentry.capture_message(e)
          end

          raise GRPC::Unknown.new('Internal server error')
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response
      end
    end
  end
end
