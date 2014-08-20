module TheMetal
  class Request
    def initialize env
      @env = env
    end
    def logger; @env['rack.logger']; end
    # etc.
  end
end
