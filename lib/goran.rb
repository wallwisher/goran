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
      # This flag will be true if the current attempt is successful
      # and does not require a retry based on the retry_if condition.
      is_final_success_for_this_attempt = false
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
          is_final_success_for_this_attempt = true
          break # Exit the retry loop
        else
          # The operation succeeded, but retry_if condition indicates a retry is needed.
          # Apply fallback for this iteration if present; loop will continue.
          result = fallback if options.has_key?(:fallback)
        end

      rescue *rescue_from => e
        # An exception occurred. is_final_success_for_this_attempt remains false.
        if i == max_tries && !rescue_last
          # If it's the last try and we are not supposed to rescue the last exception, re-raise.
          raise e
        else
          # It's not the last try, OR it is the last try and we are rescuing it.
          # Apply fallback if present.
          result = fallback if options.has_key?(:fallback)
          # Call the on_rescue callback if provided.
          on_rescue.call(e) if on_rescue.kind_of?(Proc)
          # The loop will either continue (if i < max_tries) or terminate (if i == max_tries).
        end
      ensure
        # The ensure block always runs for the current iteration.
        # We only sleep if:
        # 1. The current attempt was NOT a "final success" (i.e., is_final_success_for_this_attempt is false).
        #    This means either an exception occurred, or yield succeeded but retry_if dictated a retry.
        # 2. AND we are not on the absolute last iteration that would exit the loop anyway (i.e., i < max_tries).
        #    This prevents sleeping after the final attempt, regardless of its outcome.
        # 3. AND the interval is greater than zero.
        if !is_final_success_for_this_attempt && i < max_tries && interval > 0
          sleep interval
        end
      end
    end
    result
  end

  class DoubleFault < StandardError; end
end