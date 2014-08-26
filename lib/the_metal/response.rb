require 'the_metal'

module TheMetal
  class Response
    attr_accessor :status

    def initialize status, headers, socket
      @socket  = socket
      @status  = status

      @headers = {
        'Date'       => httpdate,
        'Connection' => 'close'
      }.merge headers
    end

    def set_header key, value
      @headers[key] = value
    end

    def get_header key
      @headers[key]
    end

    def write_head status, headers
      http_response_start = 'HTTP/1.1 '
      @socket.write "#{http_response_start}#{CODES[status.to_i] || status}\r\n"

      @headers.each do |key, value|
        write_header key, value, @socket
      end

      headers.each do |key, value|
        write_header key, value, @socket
      end

      @status = status
      @socket.write CRLF
    end

    def write chunk
      @socket.write chunk
    end

    def finish
      @socket.close
    end

    private

    require 'time'

    def write_header key, value, buf
      if value =~ /\n/
        # avoiding blank, key-only cookies with /\n+/
        buf.write value.split(/\n+/).map! { |v| "#{key}: #{v}\r\n" }.join
      else
        buf.write "#{key}: #{value}\r\n"
      end
    end

    # unicorn has an optimized version, so add a hook method to override
    def httpdate
      Time.now.httpdate
    end
  end
end
