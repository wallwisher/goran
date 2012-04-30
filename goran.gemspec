# -*- encoding: utf-8 -*-
require File.expand_path('../lib/goran/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nitesh"]
  gem.email         = ["me@coffeebite.com"]
  gem.summary       = %q{Goran runs blocks of code that return unexpected values/raise Exceptions multiple times or until when they succeed}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "goran"
  gem.require_paths = ["lib"]
  gem.version       = Goran::VERSION
  gem.description   = <<description
    Named after Goran Invanisevic, the tennis legend who won the Wimbledon after losing the final 3 times, 
    Goran provides a simple syntax to run a block of code multiple times. E.g.
    
    * run block 'x' number of times
    * run until the block returns a non-nil value
    * run until the block does not raise an exception
    * run until the block returns a non-zero value, to a maximum of 3 times, and return nil if all runs return a 0
description
end
