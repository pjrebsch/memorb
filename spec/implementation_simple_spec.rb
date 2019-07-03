RSpec.describe ImplementationSimple do
  describe '#initialize' do
    it 'retains its original behavior' do
      imp = ImplementationSimple.new
      expect(imp.counter).to eq(123)
      puts ImplementationSimple.ancestors.inspect
    end
    it 'initializes the memorb cache' do
      imp = ImplementationSimple.new
      cache = imp.instance_variable_get(:@memorb_cache)
      expect(cache).to eq(Hash.new)
    end
  end
  describe 'memorb cache' do
    it 'is not shared across instances' do
      cache1 = ImplementationSimple.new.instance_variable_get(:@memorb_cache)
      cache2 = ImplementationSimple.new.instance_variable_get(:@memorb_cache)
      expect(cache1).not_to equal(cache2)
    end
  end
end
