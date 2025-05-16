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
    # what to do on rescue
    on_rescue = options[:on_rescue]
    # time between successive calls.
    interval = options[:interval] || 0

    result = nil
    1.upto(max_tries) do |i|
      begin
        result = yield # Execute the main block of code

        # Determine if a retry is needed based on the result from yield
        needs_retry_based_on_result = false
        if retry_if.kind_of?(Proc)
          needs_retry_based_on_result = retry_if.call(result) # true if retry is needed
        else
          needs_retry_based_on_result = (retry_if != result) # true if retry is needed
        end

        if !needs_retry_based_on_result
          # The operation was successful and the retry_if condition indicates no retry is needed.
          break # Exit the retry loop
        else
          # The operation succeeded, but retry_if condition indicates a retry is needed.
          # Apply fallback for this iteration if present; loop will continue.
          result = fallback if options.has_key?(:fallback)
          
          # Sleep before next attempt if there are more tries and interval > 0
          if i < max_tries && interval > 0
            Kernel.sleep(interval)
          end
        end
      rescue *rescue_from => e
        # An exception occurred. 
        if i == max_tries && !rescue_last
          # If it's the last try and we are not supposed to rescue the last exception, re-raise.
          raise e
        else
          # It's not the last try, OR it is the last try and we are rescuing it.
          # Apply fallback if present.
          result = fallback if options.has_key?(:fallback)
          # Call the on_rescue callback if provided.
          on_rescue.call(e) if on_rescue.kind_of?(Proc)
          # Sleep before next attempt if there are more tries and interval > 0
          if i < max_tries && interval > 0
            Kernel.sleep(interval)
          end
        end
      end
    end
    result
  end

  class DoubleFault < StandardError; end
end