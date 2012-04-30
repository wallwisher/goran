require "goran/version"

module Goran
  def self.serve(options)
    # set max tries to infinity if none is given
    max_tries = options[:max_tries] || 1.0/0
    # if no retry is given, assume that the caller is just retrying to
    # handle exceptions. hence, make sure it always returns false.
    retry_if = options[:retry_if] || lambda { |x| false }
    # set fallback value only if a fallback is defined
    fallback = options[:fallback] if options.has_key?(:fallback)
    # set exceptions to rescue from. set to fake exception if none provided
    rescue_from = options[:rescue_from] || Goran::DoubleFault
    # should the last exception in the iteration be rescued from?
    rescue_last = options[:rescue_last] != false
    # time between successive calls.
    interval = options[:interval] || 0
    
    result = nil
    1.upto(max_tries) do |i|
      begin
        result = yield
        if retry_if.kind_of?(Proc)
          puts retry_if
          break unless retry_if.call(result)
        elsif retry_if != result
          break
        elsif defined? fallback
          result = fallback
        end
      rescue *rescue_from => e
        raise e if i == max_tries && !rescue_last
        result = options[:fallback] if options.has_key?(:fallback)
      ensure
        sleep interval unless interval.zero?
      end
    end
    result
  end
  
  class DoubleFault < StandardError; end
end
