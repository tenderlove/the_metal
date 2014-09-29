# the_metal

* http://github.com/tenderlove/the_metal

![heavy metal](http://stuffpoint.com/heavy-metal/image/353683-heavy-metal-heavy-metal-zombie.jpg)

## DESCRIPTION:

A spike for researching Rack 2.0

## FEATURES/PROBLEMS:

Totally experimental.  It's just a spike.

## SYNOPSIS:

An app without any middleware:

```ruby
gem 'the_metal', github: 'tenderlove/the_metal'
```

```ruby
require 'the_metal/puma'

TheMetal.create_server(->(req, res) {
  res.write_head 200, 'Content-Type' => 'text/plain'
  res.write "Hello World\n"
  res.finish
}).listen 9292, '0.0.0.0'
```

You can use a class too:

```ruby
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
```

An app that checks out a database connection when the request starts and
checks it back in when the response is finished:

```ruby
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
```

Server side output:

```
ensure database connection
-> checkout connection
<- checkin connection
```

An app that buffers responses so it can calculate a `Content-Length` header:

```ruby
require 'the_metal'
require 'the_metal/response'

class Application
  def call req, res
    res.write_head 200, 'Content-Type' => 'text/plain'
    res.write "Hello World\n"
    res.finish
  end
end

class ContentLength
  class BufferedResponse < DelegateClass(TheMetal::Response)
    def initialize delegate
      super
      @headers = {}
      @body    = []
    end

    def write_head status, headers
      self.status = status
      @headers = headers
    end

    def write chunk
      @body << chunk
    end

    def finish
      body = @body.join
      size = body.bytesize
      @headers['Content-Length'] = size
      __getobj__.write_head status, @headers
      __getobj__.write body
      super
    end
  end

  def filter req, res, chain
    puts "filtering"
    chain.next req, BufferedResponse.new(res)
  end
end

require 'the_metal/puma'
app = TheMetal.build_app [], [ContentLength.new], Application.new
server = TheMetal.create_server app
server.listen 9292, '0.0.0.0'
```

## IDEAS:

### Middleware

We should separate middleware from the server itself.  In other words,
`build_app` should probably be a separate Gem, and we can make a nicer API
for it than the above examples.

I think Rack middleware should be **out of scope** for Rack 2.0. This is
analogous to the Node.JS / Connect relationship.  We should develop a
middleware handler separately from the webserver interface.  The `build_app`
middleware API implemented here is just a suggestion and an experiment to
demonstrate how middleware _could_ work with this API.  I think Rack 2.0 should
only handle the first example.

### Webservers

Webserver should supply a request and response object to the handler.  Rack 2.0
will define the API on the request and response object, but we should keep it
to a minimum.  Rack 2.0 should implement request and response objects that
webserver implementers can reuse -- we shouldn't have code for writing headers
to a socket duplicated across many webserver implementations.

Application code should be executed immediately after the request headers have
been read in.  The request object should have an IO where post bodies can be
ready.  The IO is not rewindable.

The response object should have an output IO.  The output IO doesn't have to be
the same as the input IO.  This is entirely up to the webserver implementer.

## Tests

So far, the ideas I've laid out are sort of vague, and I've not been very
specific about the exact behavior.  To address this, I think we should develop
a test suite that web server implementors can run to ensure that all webservers
behave similarly.  Think RubySpec, but for Ruby webservers.  I've demonstrated
that with Unicorn, Puma, and WEBRick in the tests for this project.

## Finally

This is a spike. It is extremely experimental at this point, but it puts most
of my thoughts to code.  My overall idea is:

* Applications should be dealing with streams
* Request / Response objects abstract applications from specific implementations
* A middleware framework **should not** be defined by Rack 2.0.
* Test should ensure webserver compatibility

If you have ideas for changes, please open a ticket or send a pull request.
Let's make the HTTP landscape for Ruby even more amazing!

## LICENSE:

(The MIT License)

Copyright (c) 2014 Aaron Patterson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
