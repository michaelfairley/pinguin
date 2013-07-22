require 'pinguin/success'
require 'pinguin/failure'
require 'net/http'

class Pinguin
  module Checks
    class HTTP
      attr_reader :url
      attr_reader :response_code
      attr_reader :follow_redirects
      alias follow_redirects? follow_redirects
      attr_reader :redirect_limit
      attr_reader :read_timeout
      attr_reader :connect_timeout

      def initialize(options={})
        @url = options.fetch('url')
        @response_code = options.fetch('response_code', '2xx')
        @follow_redirects = options.fetch('follow_redirects', true)
        @redirect_limit = options.fetch('redirect_limit', 5)
        @read_timeout = options.fetch('read_timeout', 10)
        @connect_timeout = options.fetch('connect_timeout', 10)
        freeze
      end

      def check
        tries = 0
        uri = URI.parse(url)

        loop do
          tries += 1

          response = _execute(uri)

          if _response_code_spec =~ response.code
            return Success.new
          else
            if response.code.start_with?('3') &&
                follow_redirects? &&
                tries < redirect_limit+1
              uri = URI.parse(response['Location'])
            else
              return Failure.new
            end
          end
        end
      rescue Timeout::Error
        return Failure.new
      rescue Errno::ECONNREFUSED
        return Failure.new
      rescue SocketError => e
        case e.message
        when /\Agetaddrinfo/, /name or service not known/
          return Failure.new
        else
          raise
        end
      end

      def _request(uri)
        Net::HTTP::Get.new(uri.request_uri)
      end

      def _http(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.read_timeout = read_timeout
          http.open_timeout = connect_timeout
        end
      end

      def _execute(uri)
        _http(uri).request(_request(uri))
      end

      def _response_code_spec
        /\A#{response_code.to_s.gsub('x', '.')}\z/
      end
    end
  end
end
