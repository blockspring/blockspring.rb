lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blockspring/version'

Gem::Specification.new do |spec|
  spec.name        = 'blockspring'
  spec.version     = Blockspring::VERSION
  spec.summary     = "This gem lets you locally define a Blockspring function."
  spec.description = "Gem for defining Blockspring functions locally."
  spec.authors     = ["Don Pinkus", "Paul Katsen", "Jason Tokoph"]
  spec.email       = 'founders@blockspring.com'
  spec.files       = `git ls-files -z`.split("\x0")
  spec.homepage    = 'https://www.blockspring.com'
  spec.license     = 'MIT'

  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"

  spec.add_dependency "rest-client",  "> 1.6.7"
end
