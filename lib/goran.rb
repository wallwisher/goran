require "goran/version"

module Goran
  def self.serve(options)
    # set max tries to infinity if none is given
    max_tries = options[:max_tries] || 1.0/0
    # if no retry is given, assume that the caller is just retrying to
    # handle exceptions. hence, make sure it always returns false.
    retry_if = if options.has_key?(:retry_if) then options[:retry_if] else lambda { |x| false } end
    # set fallback value only if a fallback is defined
    fallback = options[:fallback] if options.has_key?(:fallback)
    # set exceptions to rescue from. set to fake exception if none provided
    rescue_from = options[:rescue_from] || Goran::DoubleFault
    # should the last exception in the iteration be rescued from?
    rescue_last = options[:rescue_last] != false
    # what do do on rescue
    on_rescue = options[:on_rescue]
    # time between successive calls.
    interval = options[:interval] || 0
    
    result = nil
    1.upto(max_tries) do |i|
      begin
        result = yield
        if retry_if.kind_of?(Proc)
          break unless retry_if.call(result)
        elsif retry_if != result
          break
        end
        # the flow should not come here if the result was good
        result = fallback if options.has_key?(:fallback)
      rescue *rescue_from => e
        if i == max_tries && !rescue_last
          raise e
        else
          result = fallback if options.has_key?(:fallback)
          on_rescue.call(e) if on_rescue.kind_of?(Proc)
        end
      ensure
        sleep interval unless interval.zero?
      end
    end
    result
  end
  
  class DoubleFault < StandardError; end
end
