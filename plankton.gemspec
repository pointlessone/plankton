# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plankton/version'

Gem::Specification.new do |spec|
  spec.name          = "Plankton"
  spec.version       = Plankton::VERSION
  spec.authors       = ["Alexander Mankuta"]
  spec.email         = ["cheba@pointlessone.org"]
  spec.summary       = %q{PDF file reader/writer}
  spec.description   = %q{Plankton deals with PDF files. It can read them. It understands all the basic objects. And it can write them.}
  spec.homepage      = "https://github.com/cheba/plankton"
  spec.license       = "MIT"

  spec.files         = Dir['{lib,spec}/**/*'] + %w[.rspec Gemfile LICENSE README.md Rakefile plankton.gemspec]
  spec.test_files    = Dir['spec/*_spec.rb']
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.3"
  spec.required_rubygems_version = ">= 1.3.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "rspec", "~> 2.14"
end
