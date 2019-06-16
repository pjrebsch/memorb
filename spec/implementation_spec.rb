RSpec.describe Implementation do
  describe '#initialize' do
    it 'retains its original behavior' do
      imp = Implementation.new
      expect(imp.counter).to eq(123)
    end
    it 'initializes the memorb cache' do
      imp = Implementation.new
      cache = imp.instance_variable_get(:@memorb_cache)
      expect(cache).to eq(Hash.new)
    end
  end
  describe 'memorb cache' do
    it 'should not be shared across instances' do
      cache1 = Implementation.new.instance_variable_get(:@memorb_cache)
      cache2 = Implementation.new.instance_variable_get(:@memorb_cache)
      expect(cache1).not_to equal(cache2)
    end
  end
end
