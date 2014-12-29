module TheMetal
  class FilterChain < Struct.new(:middleware, :endpoint)
    def start
      middleware.each(&:start)
      endpoint.start
    end

    def call request, response
      if middleware.empty?
        endpoint.call request, response
      else
        chain = self.class.new middleware.drop(1), endpoint
        middleware.first.filter request, response, chain
      end
    end
    alias :next :call
  end
end
