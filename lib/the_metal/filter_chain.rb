module TheMetal
  class FilterChain < Struct.new(:middleware, :endpoint)
    def start
      middleware.each(&:start)
      endpoint.start
    end

    def serve request, response
      if middleware.empty?
        endpoint.serve request, response
      else
        chain = self.class.new middleware.drop(1), endpoint
        middleware.first.filter request, response, chain
      end
    end
    alias :next :serve
  end
end
