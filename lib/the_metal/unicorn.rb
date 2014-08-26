require 'the_metal/request'
require 'the_metal/response'

module TheMetal
  class Unicorn < Unicorn::HttpServer
    def start
      @app.start_app if @app.respond_to? :start_app
      super
    end

    def process_client client
      env = @request.read client

      default_headers = {
        'Date'       => httpdate,
        'Connection' => 'close'
      }

      req = TheMetal::Request.new env
      res = TheMetal::Response.new 200, default_headers, client
      @app.call req, res
    rescue => e
      handle_error client, e
    end

    class Proxy
      def initialize app
        @app = app
      end

      def listen port, address
        TheMetal::Unicorn.new(@app,
                              { :listeners => [ "#{address}:#{port}" ],
                                :logger => Logger.new(nil) }
                             ).start.join
      end
    end
  end

  def self.create_server app
    Unicorn::Proxy.new app
  end
end
