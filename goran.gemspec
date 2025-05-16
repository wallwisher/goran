# -*- encoding: utf-8 -*-
require File.expand_path('../lib/goran/version', __FILE__)

Gem::Specification.new do |gem|
  gem.date          = Time.now.strftime('%Y-%m-%d')
  gem.authors       = ["Nitesh"]
  gem.email         = ["nitesh@wallwisher.com"]
  gem.summary       = %q{Goran is a ruby library to run blocks of code that return unexpected values/raise Exceptions multiple times or until they succeed}
  gem.homepage      = "http://github.com/wallwisher/goran"

  gem.files         = %w[README.md Rakefile LICENSE]
  gem.files         += Dir.glob('lib/**/*')
  gem.files         += Dir.glob('bin/**/*')
  gem.files         += Dir.glob('spec/**/*')
  gem.name          = "goran"
  gem.require_paths = ["lib"]
  gem.version       = Goran::VERSION
  
  gem.add_development_dependency 'rspec', '~> 3.0'
  
  gem.description   = <<description
    Named after Goran Invanisevic, the tennis legend who won the Wimbledon after losing the final 3 times, 
    Goran provides a simple syntax to run a block of code multiple times. E.g.
    
    * run block 'x' number of times
    * run until the block returns a non-nil value
    * run until the block does not raise an exception
    * run until the block returns a non-zero value, to a maximum of 3 times, and return nil if all runs return a 0
    
    Goran is especially useful for running network calls which have unexpected outputs like 404, timeouts. It is an
    easy way to build in retry logic into these calls and handle cases where these calls do not succeed at all.
description
end
