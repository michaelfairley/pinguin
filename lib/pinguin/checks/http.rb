require 'pinguin/success'
require 'pinguin/failure'
require 'pinguin/checks'
require 'net/http'

class Pinguin
  module Checks
    class HTTP
      Pinguin::Checks.register('http', self)

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

      def check(tries=1, current_url=url)
        response = _execute(current_url)

        if _response_code_spec =~ response.code
          return Success.new
        elsif response.code.start_with?('3') &&
              follow_redirects? &&
              tries < redirect_limit+1
          check(tries+1, response['Location'])
        else
          return Failure.new
        end
      rescue Timeout::Error
        return Failure.new
      rescue Errno::ECONNREFUSED
        return Failure.new
      rescue SocketError => e
        return Failure.new
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

      def _execute(url)
        uri = URI.parse(url)
        _http(uri).request(_request(uri))
      end

      def _response_code_spec
        /\A#{response_code.to_s.gsub('x', '.')}\z/
      end
    end
  end
end
