require 'the_metal'
require 'minitest/autorun'
require 'drb'
require 'drb/unix'
require 'tempfile'

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

# Locked at 1 until we bind to different ports.
Minitest.parallel_executor = ForkingExecutor.new(1)
