# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name          = 'the_metal'
  gem.summary       = 'A spike for thoughts about Rack 2.0'
  gem.description   = gem.summary
  gem.authors       = ['Aaron Patterson']
  gem.email         = ['aaron.patterson@gmail.com']
  gem.homepage      = 'https://github.com/tenderlove/the_metal'
  gem.require_paths = ['lib']
  gem.version       = '0.0.0'
  gem.files         = `git ls-files`.split("\n").reject { |name| name.include?('examples') }
  gem.test_files    = `git ls-files -- {spec}/*`.split("\n")
  gem.license       = 'MIT'
end
