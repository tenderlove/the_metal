require 'helper'

class TestUnicorn < TheMetal::WebServerTest
  def self.webserver; :unicorn; end

  include TheMetal::StatusTests

  def setup
    require 'unicorn'
    require 'the_metal/unicorn'
    super
  end

  def shutdown
    Process.kill "QUIT", $$
  end
end
