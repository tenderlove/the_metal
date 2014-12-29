require 'the_metal/puma'

TheMetal.create_server(->(req, res) {
  res.write_head 200, 'Content-Type' => 'text/plain'
  res.write "Hello World\n"
  res.finish
}).listen 9292, '0.0.0.0'
