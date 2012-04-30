# Goran

Named after Goran Invanisevic, the tennis legend who won the Wimbledon after losing the final 3 times, Goran provides a simple syntax to run a block of code multiple times. E.g.
    
* run block 'x' number of times
* run until the block returns a non-nil value
* run until the block does not raise an exception
* run until the block returns a non-zero value, to a maximum of 3 times, and return nil if all runs return a 0
    
Goran is especially useful for running network calls which have unexpected outputs like 404, timeouts. It is an easy way to build in retry logic into these calls and handle cases where these calls do not succeed at all.

## Installation

Add this line to your application's Gemfile:

    gem 'goran'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install goran

## Usage

	require 'goran'
	
Run a block until it stops returning `0`
	
	Goran.serve :retry_if => 0 do
	  #block
	end

Run a block until it returns a value > 0; run it a maximum of 3 times
	
	Goran.serve :max_tries => 3, :retry_if => { |x| x <= 0 } do
	  #block
	end
	
Run a block until it stops returning `0`; run it a maximum of 3 times; wait for a second between calls
	
	Goran.serve :max_tries => 3, :retry_if => 0, :interval => 1 do
	  #block
	end	
	
Run a block until it stops returning `0`; run it a maximum of 3 times; return `nil` if it doesn't return a non-zero value even after 3 tries

	Goran.serve :max_tries => 3, :retry_if => 0, :fallback => nil do
	  #block
	end

Run a block until it doesn't raise a `StandardError`

	Goran.serve :rescue_from => StandardError do
	  #block
	end

Run a block until it doesn't raise a `StandardError`; run it a maximum of 3 times; supress error all three times

	Goran.serve :max_tries => 3, :rescue_from => StandardError do
	  #block
	end
	
Run a block until it doesn't raise a `StandardError`; run it a maximum of 3 times; do not supress an error in the last run

	Goran.serve :max_tries => 3, :rescue_from => StandardError, :rescue_last => false
	  #block
	end

Run a block until it doesn't raise a `StandardError`; run it a maximum of 3 times; run a block when an error happens (say for logging the error)

	Goran.serve :max_tries => 3, :rescue_from => StandardError, :on_rescue => lambda { |e| logger.error e }
	  #block
	end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
