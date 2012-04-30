require "goran/version"

module Goran
  def self.serve(options)
    tries = options[:tries] || 1.0/0
    until_check = options[:until] || lambda { |x| true }
    rescue_classes = options[:rescue] || Goran::DoubleFault
    sleep_time = options[:sleep] || 0
    result = nil

    1.upto(tries) do
      begin
        result = yield
        break if (until_check.kind_of? Proc && until_check.call(result)) || until_check == result
      rescue *rescue_classes
        #do nothing
      ensure
        sleep sleep_time
      end
    end
    result
  end
  
  class DoubleFault < StandardError; end
end
