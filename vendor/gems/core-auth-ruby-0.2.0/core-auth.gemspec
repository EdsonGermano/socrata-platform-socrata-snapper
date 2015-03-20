# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'core/auth/version'

Gem::Specification.new do |spec|
  spec.name          = "core-auth-ruby"
  spec.version       = Core::Auth::VERSION
  spec.authors       = ["Stan Rawrysz"]
  spec.email         = ["stan.rawrysz@socrata.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://nocrata.com'
  end

  spec.summary       = %q{Core authentication library}
  spec.description   = %q{Get a core session cookie for authenticating your app against core.}
  spec.homepage      = "http://github.com/socrata/core-auth-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'addressable', '~> 2.3'
  spec.add_dependency 'nokogiri', '~> 1.6'
  spec.add_dependency 'httparty', '~> 0.13'
end
