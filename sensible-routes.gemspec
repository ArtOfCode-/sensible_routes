
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sensible_routes/version'

Gem::Specification.new do |spec|
  spec.name          = 'sensible-routes'
  spec.version       = SensibleRoutes::VERSION
  spec.authors       = ['ArtOfCode-']
  spec.email         = ['hello@artofcode.co.uk']

  spec.summary       = 'Simple and comprehensible route introspection library for Rails.'
  spec.homepage      = 'https://github.com/ArtOfCode-/sensible-routes'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'rails', '~> 5'
end
