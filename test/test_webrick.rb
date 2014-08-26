require 'helper'
require 'webrick'

class TestWEBRick < TheMetal::WebServerTest
  def self.webserver; :webrick; end

  include TheMetal::StatusTests

  def setup
    require 'the_metal/webrick'
    super
  end

  def shutdown
    @server.stop
  end
end
