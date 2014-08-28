class Application
  def call req, res
    res.write_head 200, 'Content-Type' => 'text/plain'
    res.write "Hello World\n"
    res.finish
  end
end

require 'the_metal/puma'
server = TheMetal.create_server Application.new
server.listen 9292, '0.0.0.0'
