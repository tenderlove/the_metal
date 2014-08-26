require 'the_metal'
require 'minitest/autorun'
require 'drb'
require 'drb/unix'
require 'tempfile'
require 'net/http'

Thread.abort_on_exception = true

class ForkingExecutor
  class Server
    include DRb::DRbUndumped

    def initialize
      @queue = Queue.new
    end

    def record reporter, result
      reporter.record result
    end

    def << o
      o[2] = DRbObject.new(o[2]) if o
      @queue << o
    end
    def pop; @queue.pop; end
  end

  def initialize size
    @size  = size
    @queue = Server.new
    file   = File.join Dir.tmpdir, Dir::Tmpname.make_tmpname('tests', 'fd')
    @url   = "drbunix://#{file}"
    @pool  = nil
    DRb.start_service @url, @queue
  end

  def << work
    @queue << work
  end

  def shutdown
    pool = @size.times.map {
      fork {
        DRb.stop_service
        queue = DRbObject.new_with_uri @url
        while job = queue.pop
          klass    = job[0]
          method   = job[1]
          reporter = job[2]
          result = Minitest.run_one_method klass, method
          if result.error?
            translate_exceptions result
          end
          queue.record reporter, result
        end
      }
    }
    @size.times { @queue << nil }
    pool.each { |pid| Process.waitpid pid }
  end

  private
  def translate_exceptions(result)
    result.failures.map! { |e|
      begin
        Marshal.dump e
        e
      rescue TypeError
        ex = Exception.new e.message
        ex.set_backtrace e.backtrace
        Minitest::UnexpectedError.new ex
      end
    }
  end
end

module TheMetal
  class WebServerTest < Minitest::Test
    parallelize_me!

    def setup
      super

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

    def start_server
      Thread.new { yield }
    end
  end

  module StatusTests
    class Application
      def initialize code
        @code = code
      end

      def call req, res
        res.write_head @code, 'Content-Type' => 'text/plain'
        res.write "Hello World\n"
        res.finish
      end
    end

    def test_server_404
      start_server do
        @server = TheMetal.create_server Application.new 404
        @server.listen @connect_point.port, @connect_point.host
      end

      assert_equal 404, response.code.to_i
      assert_equal 'text/plain', response['Content-Type']
      assert_equal "Hello World\n", response.body
    end

    def test_server_200
      start_server do
        @server = TheMetal.create_server Application.new 200
        @server.listen @connect_point.port, @connect_point.host
      end

      assert_equal 200, response.code.to_i
      assert_equal 'text/plain', response['Content-Type']
      assert_equal "Hello World\n", response.body
    end
  end
end

# Locked at 1 until we bind to different ports.
Minitest.parallel_executor = ForkingExecutor.new(1)
