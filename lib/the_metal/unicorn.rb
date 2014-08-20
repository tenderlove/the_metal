require 'the_metal/request'
require 'the_metal/response'

module TheMetal
  class Unicorn < Unicorn::HttpServer
    def start
      @app.start_app
      super
    end

    def process_client client
      env = @request.read client
      req = TheMetal::Request.new env
      res = TheMetal::Response.new req, client
      @app.serve req, res
    rescue => e
      handle_error client, e
    end
  end

  def self.boot app
    TheMetal::Unicorn.new(app, {}).start.join
  end
end
