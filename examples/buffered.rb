require 'the_metal'
require 'the_metal/response'

class Application
  def call req, res
    res.write_head 200, 'Content-Type' => 'text/plain'
    res.write "Hello World\n"
    res.finish
  end
end

class ContentLength
  class BufferedResponse < DelegateClass(TheMetal::Response)
    def initialize delegate
      super
      @headers = {}
      @body    = []
    end

    def write_head status, headers
      self.status = status
      @headers = headers
    end

    def write chunk
      @body << chunk
    end

    def finish
      body = @body.join
      size = body.bytesize
      @headers['Content-Length'] = size
      __getobj__.write_head status, @headers
      __getobj__.write body
      super
    end
  end

  def filter req, res, chain
    puts "filtering"
    chain.next req, BufferedResponse.new(res)
  end
end

require 'the_metal/puma'
app = TheMetal.build_app [], [ContentLength.new], Application.new
server = TheMetal.create_server app
server.listen 9292, '0.0.0.0'
