require 'the_metal/request'
require 'the_metal/response'
require 'puma/cli'

module TheMetal
  class Puma
    def initialize app
      @app = app
      app.start_app
    end

    def call env
      env['rack.hijack'].call
      socket = env['rack.hijack_io']

      req = TheMetal::Request.new env
      res = TheMetal::Response.new req, socket
      @app.serve req, res
      [nil, {}, nil]
    end
  end

  def self.boot app
    cli = ::Puma::CLI.new([])
    cli.options[:app] = TheMetal::Puma.new(app)
    cli.run
  end
end

