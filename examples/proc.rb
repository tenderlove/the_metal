require 'the_metal/puma'

module TheMetal
  class << self
    def patched_create_server *args
      puts "Haha #{args.inspect}"
      original_create_server *args
    end

    alias :original_create_server :create_server
    alias :create_server :patched_create_server
  end
end

TheMetal.create_server(->(req, res) {
  res.write_head 200, 'Content-Type' => 'text/plain'
  res.write "Hello World\n"
  res.finish
}).listen 9292, '0.0.0.0'
