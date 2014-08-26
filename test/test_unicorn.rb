require 'helper'
require 'net/http'

class TestUnicorn < MiniTest::Test
  parallelize_me!

  def self.webserver; :unicorn; end

  class Application
    def initialize code
      @code = code
    end

    def serve req, res
      res.write_head @code, 'Content-Type' => 'text/plain'
      res.write "Hello World\n"
      res.close
    end
  end

  Thread.abort_on_exception = true

  def setup
    require 'unicorn'
    require 'the_metal/unicorn'

    @connect_point = URI('http://127.0.0.1:1337')
    @t = Thread.new {
      resp = begin
               Net::HTTP.get_response @connect_point
             rescue
               retry
             end
      shutdown
      resp
    }
  end

  def response
    @t.join
    @t.value
  end

  def test_server_404
    server = TheMetal.create_server Application.new 404
    server.listen @connect_point.port, @connect_point.host

    assert_equal 404, response.code.to_i
    assert_equal 'text/plain', response['Content-Type']
    assert_equal "Hello World\n", response.body
  end

  def test_server_200
    server = TheMetal.create_server Application.new 200
    server.listen @connect_point.port, @connect_point.host

    assert_equal 200, response.code.to_i
    assert_equal 'text/plain', response['Content-Type']
    assert_equal "Hello World\n", response.body
  end

  def shutdown
    Process.kill "QUIT", $$
  end
end
