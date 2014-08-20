require 'the_metal'

module TheMetal
  class Response
    attr_accessor :status

    def initialize req, socket
      @req     = req
      @socket  = socket
      @headers = {}
      @status  = nil
    end

    def write_head status, headers
      http_response_start = 'HTTP/1.1 '
      buf = "#{http_response_start}#{CODES[status.to_i] || status}\r\n" \
        "Date: #{httpdate}\r\n" \
      "Connection: close\r\n"
      headers.each do |key, value|
        case key
        when %r{\A(?:Date\z|Connection\z)}i
          next
        else
          if value =~ /\n/
            # avoiding blank, key-only cookies with /\n+/
            buf << value.split(/\n+/).map! { |v| "#{key}: #{v}\r\n" }.join
          else
            buf << "#{key}: #{value}\r\n"
          end
        end
      end

      @status = status
      @socket.write(buf << CRLF)
    end

    def write chunk
      @socket.write chunk
    end

    def close
      @socket.close
    end

    private

    require 'time'

    # unicorn has an optimized version, so add a hook method to override
    def httpdate
      Time.now.httpdate
    end
  end
end
