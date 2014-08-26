require 'the_metal/filter_chain'
require 'rack/utils'

module TheMetal
  VERSION = '1.0.0'
  CODES = Rack::Utils::HTTP_STATUS_CODES.each_with_object({}) { |(code,msg),hash|
    hash[code] = "#{code} #{msg}"
  }
  CRLF = "\r\n"

  class Application < Struct.new :events, :chain
    def start_app
      events.each { |e| e.start_app self }
    end

    def call req, res
      events.each { |e| e.start_request req, res }
      chain.call req, res
      events.reverse_each { |e| e.finish_request req, res }
    end
  end

  def self.build_app events, filters, app
    chain = if filters.empty?
              app
            else
              FilterChain.new filters, app
            end
    Application.new events, chain
  end
end
