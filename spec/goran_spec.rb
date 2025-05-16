describe Goran do
  # Helper to simulate a sequence of actions/results from the yielded block
  def mock_action_sequence(actions)
    call_index = -1
    lambda do
      call_index += 1
      action = actions[call_index] || raise("Test Error: Too many calls to mock_action_sequence block")
      if action.is_a?(Class) && action < Exception
        raise action, "Mocked exception from sequence"
      elsif action.is_a?(Proc)
        action.call
      else
        action # return a value
      end
    end
  end

  describe 'Core Functionality' do
    it 'serves for a maximum of x tries when retry_if lambda forces retries until max_tries' do
      count = 0
      # Block returns current count. Lambda always suggests retry.
      # Try 1: count=1. retry_if -> true. Result for Goran's iteration: 1.
      # Try 2: count=2. retry_if -> true. Result for Goran's iteration: 2.
      # Try 3: count=3. retry_if -> true. Max tries reached. Result for Goran's iteration: 3.
      # Final result returned by Goran.serve is the result of the last execution of the block.
      result_val = Goran.serve(max_tries: 3, retry_if: lambda {|_| true }) { count += 1; count }
      expect(result_val).to eq(3)
      expect(count).to eq(3) # Confirms the block was executed 3 times
    end

    it 'stops trying if the block runs successfully and no specific result-based retry_if is given (uses default)' do
      count = 0
      # Default retry_if is lambda {|_| false}, meaning "don't retry based on result, it's a success".
      # Try 1: count=1, block returns 1. default_retry_if(1) -> false. Success. Break.
      final_result = Goran.serve(max_tries: 3) { count += 1; count } # No :retry_if provided
      expect(final_result).to eq(1)
      expect(count).to eq(1)
    end

    it 'stops trying if the block runs successfully and its result matches the retry_if value' do
      count = 0
      # retry_if: 1 means "success if block returns 1".
      # Try 1: count=1, block returns 1. (retry_if value 1) == (result 1) -> true. Success. Break.
      final_result = Goran.serve(max_tries: 3, retry_if: 1) { count += 1; count }
      expect(final_result).to eq(1)
      expect(count).to eq(1)
    end

    it 'uses fallback value if one is provided and all tries are exhausted due to retry_if lambda' do
      count = 0
      # Block always returns 0. retry_if lambda always says to retry.
      # Goran.serve should return the fallback value.
      expect(
        Goran.serve(max_tries: 3, retry_if: lambda {|_| true }, fallback: 'hello from fallback') { count += 1; 0 }
      ).to eq('hello from fallback')
      expect(count).to eq(3) # Block still runs 3 times
    end

    it 'uses fallback value if one is provided and all tries are exhausted due to exceptions (and rescue_last is true)' do
      count = 0
      # rescue_last is true by default. All exceptions are caught.
      # Goran.serve should return the fallback value.
      expect(
        Goran.serve(max_tries: 3, fallback: 'fallback_after_exceptions', rescue_from: StandardError) { count += 1; raise StandardError, 'Boo' }
      ).to eq('fallback_after_exceptions')
      expect(count).to eq(3) # Block attempts 3 times
    end

    it 'protects from exceptions (when rescue_last is true by default) and returns fallback if provided' do
      result = Goran.serve(max_tries: 3, fallback: 'safe_fallback', rescue_from: StandardError) { raise StandardError, 'Boo' }
      expect(result).to eq('safe_fallback')
    end

    it 'protects from exceptions (when rescue_last is true by default) and returns nil if no fallback and no successful yield' do
      result = Goran.serve(max_tries: 3, rescue_from: StandardError) { raise StandardError, 'Boo' }
      expect(result).to be_nil # Default result if nothing else sets it
    end

    it 'does not protect from exception on the last run if rescue_last is false' do
      action_block = lambda { raise StandardError, 'Custom Boo' }
      expect {
        Goran.serve(max_tries: 3, rescue_from: StandardError, rescue_last: false, &action_block)
      }.to raise_error(StandardError, 'Custom Boo')
    end

    it 'runs a proc on rescue for each rescued attempt' do
      on_rescue_count = 0
      action_block = lambda { raise StandardError, 'Boo for on_rescue' }
      # rescue_last is true by default, so all 3 exceptions will be rescued.
      Goran.serve(
        max_tries: 3,
        rescue_from: StandardError,
        on_rescue: lambda {|e| on_rescue_count +=1 },
        &action_block
      )
      expect(on_rescue_count).to eq(3)
    end
  end

  describe 'Sleep Behavior' do
    it 'does not sleep if interval is 0, even if retries occur (due to exception)' do
      expect(Kernel).not_to receive(:sleep)
      Goran.serve(max_tries: 2, interval: 0, rescue_from: StandardError, on_rescue: lambda {|_|}) { raise StandardError }
    end

    it 'does not sleep if interval is 0, even if retries occur (due to retry_if)' do
      expect(Kernel).not_to receive(:sleep)
      call_count = 0
      # Try 1: call_count=0 -> 1. retry_if (1==1) -> true. Retry. (No sleep as interval is 0)
      # Try 2: call_count=1 -> 2. (No more retries as max_tries is 2)
      Goran.serve(max_tries: 2, interval: 0, retry_if: lambda {|_| call_count == 1 }) { call_count += 1 }
    end

    it 'does not sleep on an immediate successful attempt when interval is positive (default retry_if)' do
      expect(Kernel).not_to receive(:sleep)
      Goran.serve(max_tries: 3, interval: 0.1) { "success" }
    end

    it 'does not sleep on an immediate successful attempt when interval is positive (matching retry_if value)' do
      expect(Kernel).not_to receive(:sleep)
      Goran.serve(max_tries: 3, interval: 0.1, retry_if: "success_value") { "success_value" }
    end

    it 'sleeps before a retry due to an exception, if not the last attempt and interval is positive' do
      expect(Kernel).to receive(:sleep).with(0.1).once
      
      action_block = mock_action_sequence([StandardError, "success_after_exception"])
      Goran.serve(
        max_tries: 2,
        interval: 0.1, 
        rescue_from: StandardError,
        on_rescue: lambda {|_|},
        &action_block
      )
    end

    it 'sleeps before a retry due to a retry_if condition, if not the last attempt and interval is positive' do
      expect(Kernel).to receive(:sleep).with(0.1).once
      
      actions_executed = 0
      Goran.serve(
        max_tries: 2,
        interval: 0.1,
        retry_if: lambda {|_| actions_executed == 1 }
      ) do
        actions_executed += 1
        "actions_executed_value: #{actions_executed}"
      end
      
      expect(actions_executed).to eq(2) # Verify block ran twice
    end

    it 'does not sleep after a successful attempt that follows an exception retry (final success)' do
      expect(Kernel).to receive(:sleep).with(0.1).once
      
      action_block = mock_action_sequence([StandardError, "final_success_val"])
      Goran.serve(
        max_tries: 2,
        interval: 0.1,
        rescue_from: StandardError,
        on_rescue: lambda {|_|},
        retry_if: "final_success_val",
        &action_block
      )
    end

    it 'does not sleep after a successful attempt that follows a retry_if-forced retry (final success)' do
      expect(Kernel).to receive(:sleep).with(0.1).once
      
      call_count = 0
      block_results = ["retry_trigger_value", "ultimate_success_value"]
      Goran.serve(
        max_tries: 2,
        interval: 0.1,
        retry_if: lambda {|res| res == "retry_trigger_value" }
      ) do
        current_result = block_results[call_count]
        call_count += 1
        current_result
      end
      
      expect(call_count).to eq(2) # Ensure block ran twice
    end

    it 'does not sleep after the final attempt if max_tries is reached (due to persistent exceptions)' do
      expect(Kernel).to receive(:sleep).with(0.1).once
      
      Goran.serve(
        max_tries: 2,
        interval: 0.1,
        rescue_from: StandardError,
        on_rescue: lambda {|_|}
      ) { raise StandardError, 'persistent_failure_exception' }
    end

    it 'does not sleep after the final attempt if max_tries is reached (due to persistent retry_if condition)' do
      expect(Kernel).to receive(:sleep).with(0.1).once
      
      call_count = 0
      Goran.serve(
        max_tries: 2,
        interval: 0.1,
        retry_if: lambda {|_| true } # Always suggest retry
      ) { call_count += 1 }
      
      expect(call_count).to eq(2) # Ensure block ran twice
    end
  end
end