# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mutx/version'

Gem::Specification.new do |spec|
  spec.name                   = "mutx"
  spec.version                = Mutx::VERSION
  spec.authors                = ["Roman Rodriguez"]
  spec.email                  = ["roman.g.rodriguez@gmail.com"]
  spec.summary                = %q{Mutx lets you expose executions easily}
  spec.description            = %q{Exposes executions easily}
  spec.homepage               = "https://github.com/romanrod/mutx"
  spec.license                = "MIT"
  spec.required_ruby_version  = ">= 2.0.0"

  spec.files                  = `git ls-files -z`.split("\x0")
  spec.executables            = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files             = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths          = ["lib"]

  # spec.add_dependency 'digest'
  spec.add_dependency 'thor'
  spec.add_dependency 'cuba'
  spec.add_dependency 'unicorn'
  spec.add_dependency 'json', '~> 2.0.2'
  #spec.add_dependency 'mongoid', '~> 5.1.0'
  spec.add_dependency 'mongo', '2.2.5'
  spec.add_dependency 'redis'
  spec.add_dependency 'sidekiq'
  spec.add_dependency 'bson_ext'
  spec.add_dependency 'colorize'
  spec.add_dependency 'github-markup'
  spec.add_dependency 'redcarpet'
  spec.add_dependency 'gmail'
  spec.add_dependency 'mote'
  spec.add_dependency 'require_all'
  spec.add_dependency 'byebug'
  spec.add_dependency 'shotgun'
  spec.add_dependency 'rufus-scheduler'
  spec.add_dependency 'mail'
  spec.add_dependency 'basica'
  spec.add_dependency 'sidetiq'
  spec.add_dependency 'chronic'
  #spec.add_dependency 'zip'


  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "cucumber"
end
