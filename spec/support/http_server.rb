require 'webrick'

class HTTPServer
  attr_reader :ssl, :port

  def self.run
    new.tap(&:start)
  end

  def initialize(ssl=false)
    @ssl = ssl
  end

  def start
    raise  if running?
    @port = 8000

    @server = WEBrick::HTTPServer.new(
      :Port => port,
      :Logger => WEBrick::Log.new("/dev/null"),
      :AccessLog => [],
    )

    @server.mount_proc '/' do |req, res|
      query_string = req.query_string || ''
      params = Hash[query_string.split("&").map{|p| p.split("=")}]

      response_code = req.path[1..-1]

      if params['sleep']
        sleep params['sleep'].to_i
      end

      if response_code.start_with?('3')
        to = params.fetch('to', '200')
        times = params.fetch('times', 1).to_i
        if times > 1
          res["Location"] = "/#{response_code}?to=#{to}&times=#{times-1}"
        else
          res["Location"] = "/#{to}"
        end
      end

      res.status = response_code
    end

    @thread = Thread.new{ @server.start }

    @port
  end

  def running?
    !!@server
  end

  def stop
    @server.shutdown
    @thread.join
    @server = @thread = nil
  end
end
