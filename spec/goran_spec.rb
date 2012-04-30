describe Goran do
  it 'serves for a maximum of x tries' do
    count = 0
    Goran.serve(max_tries: 3, retry_if: lambda {|x| [1,2,3].include? x}) { count += 1 }.should == 3
  end
  
  it 'stops trying if the block runs successfully' do
    count = 0
    Goran.serve(max_tries: 3, retry_if: 0) { count+=1 }.should == 1
  end
  
  it 'uses fallback value if one is provided and none of the tries are successful' do
    count = 0
    Goran.serve(max_tries: 3, retry_if: nil, fallback: 'hello') { nil }.should == 'hello'
  end
  
  it 'protects from exceptions' do
    expect { Goran.serve(max_tries: 3, retry_if: 0, rescue_from: StandardError) { raise StandardError, 'Boo' } }.to_not raise_error
  end
  
  it 'does not protect from exception on the last run if so desired' do
    expect { Goran.serve(max_tries: 3, retry_if: 0, rescue_from: [StandardError, ArgumentError], rescue_last: false) { raise StandardError, 'Boo' } }.to raise_error
  end
  
  it 'runs a proc on rescue if one is provided' do
    count = 0
    Goran.serve(max_tries: 3, retry_if: 0, rescue_from: StandardError, on_rescue: lambda {|e| count+=1 }) { raise StandardError, 'Boo' }
    count.should == 3
  end
end