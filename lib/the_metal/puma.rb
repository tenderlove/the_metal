require 'the_metal/request'
require 'the_metal/response'
require 'puma'

module TheMetal
  class Puma
    def initialize app
      @app = app
      app.start_app if app.respond_to? :start_app
    end

    def call env
      env['rack.hijack'].call
      socket = env['rack.hijack_io']

      default_headers = { }
      req = TheMetal::Request.new env
      res = TheMetal::Response.new 200, default_headers, socket
      @app.call req, res
      [nil, {}, nil]
    end

    class Proxy
      def initialize app
        @app = app
        @serv = ::Puma::Server.new Puma.new @app
      end

      def stop
        @serv.stop
      end

      def listen port, address
        @serv.add_tcp_listener address, port
        @serv.run
        sleep
      end
    end
  end

  def self.create_server app
    Puma::Proxy.new app
  end
end

