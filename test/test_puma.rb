require 'helper'

class TestPuma < TheMetal::WebServerTest
  def self.webserver; :puma; end

  include TheMetal::StatusTests

  def setup
    require 'the_metal/puma'
    super
  end

  def shutdown
    @server.stop
  end
end
