require 'the_metal'

class Application
  def call req, res
    res.write_head 200, 'Content-Type' => 'text/plain'
    res.write "Hello World\n"
    res.finish
  end
end

class DBEvents
  def start_app app
    puts "ensure database connection"
  end

  def start_request req, res
    puts "-> checkout connection"
  end

  def finish_request req, res
    puts "<- checkin connection"
  end
end

require 'the_metal/puma'
app = TheMetal.build_app [DBEvents.new], [], Application.new
server = TheMetal.create_server app
server.listen 9292, '0.0.0.0'
