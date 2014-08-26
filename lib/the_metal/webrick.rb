require 'webrick'
require 'logger'
require 'the_metal/request'
require 'the_metal/response'

module TheMetal
  def self.create_server app
    WEBrick::Proxy.new app
  end

  class WEBrick < ::WEBrick::HTTPServlet::AbstractServlet
    class Proxy
      def initialize app
        @app = app
      end

      def listen port, address
        options = {
          BindAddress: address,
          Port: port,
          OutputBufferSize: 5,
          Logger: Logger.new(nil)
        }
        @server = ::WEBrick::HTTPServer.new(options)
        @server.mount "/", WEBrick, @app
        @server.start
      end

      def stop
        @server.shutdown
      end
    end

    def initialize(server, app)
      super server
      @app = app
    end

    class Response
      def initialize webrick_response, socket
        @webrick_response = webrick_response
        @socket           = socket
      end

      def status= status
        @webrick_response.status = status
      end

      def status
        @webrick_response.status
      end

      def write_head status, headers
        self.status = status

        headers.each do |key, value|
          @webrick_response[key] = value
        end
      end

      def write chunk
        @socket.write chunk
      end

      def finish
        @socket.close
      end
    end

    def service req, res
      env = req.meta_vars
      env.delete_if { |k, v| v.nil? }

      env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
      env["QUERY_STRING"] ||= ""

      rd, wr = IO.pipe
      res.body = rd
      res.chunked = true

      m_req = TheMetal::Request.new env
      m_res = Response.new res, wr
      @app.call m_req, m_res
    end
  end
end
