require 'pinguin/success'
require 'pinguin/failure'
require 'net/http'

module Pinguin
  module Checks
    class HTTP
      attr_reader :url
      attr_reader :response_code
      attr_reader :follow_redirects
      alias follow_redirects? follow_redirects
      attr_reader :redirect_limit

      def initialize(options={})
        @url = options.fetch('url')
        @response_code = options.fetch('response_code', '2xx')
        @follow_redirects = options.fetch('follow_redirects', true)
        @redirect_limit = options.fetch('redirect_limit', 5)
        freeze
      end

      def check
        tries = 0
        uri = URI.parse(url)

        loop do
          tries += 1

          response = _http(uri).request(_request(uri))

          if _response_code_spec =~ response.code
            return Success.new
          else
            if response.code.start_with?('3') && follow_redirects? && tries < redirect_limit+1
              uri = URI.parse(response['Location'])
              next
            else
              return Failure.new
            end
          end
        end
      end

      def _request(uri)
        request = Net::HTTP::Get.new(uri.request_uri)
      end

      def _http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
      end

      def _response_code_spec
        /\A#{response_code.to_s.gsub('x', '.')}\z/
      end
    end
  end
end
