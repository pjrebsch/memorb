RSpec.describe 'Memorb::InstanceMethods' do
  describe '#memorb?' do
    it 'returns true' do
      imp = Implementation.new
      expect(imp.memorb?).to be(true)
    end
  end
  describe '#memorb_reset!' do
    it 'resets the memorb cache' do
      imp = Implementation.new
      cache1 = imp.instance_variable_get(:@memorb_cache)
      imp.memorb_reset!
      cache2 = imp.instance_variable_get(:@memorb_cache)
      expect(cache1).not_to equal(cache2)
      expect(cache2).to eq(Memorb::Core.fresh_cache)
    end
  end
  describe '#memorb_write' do
    it 'stores a value in the cache' do
      imp = Implementation.new
      key, value = :key, 'value'
      imp.memorb_write(key, value)
      cache = imp.instance_variable_get(:@memorb_cache)
      expect(cache).to include([key] => value)
    end
    it 'accepts multiple arguments as the key' do
      imp = Implementation.new
      key, value = [:k1, :k2, :k3], 'value'
      imp.memorb_write(*key, value)
      cache = imp.instance_variable_get(:@memorb_cache)
      expect(cache).to include(key => value)
    end
    it 'returns the value' do
      imp = Implementation.new
      key, value = :key, 'value'
      result = imp.memorb_write(key, value)
      expect(result).to equal(value)
    end
  end
  describe '#memorb_read' do
    it 'retrieves a value from the cache' do
      imp = Implementation.new
      key, value = :key, 'value'
      cache = imp.instance_variable_get(:@memorb_cache)
      cache[[key]] = value
      result = imp.memorb_read(key)
      expect(result).to equal(value)
    end
    context 'when a value has not been set' do
      it 'returns nil' do
        imp = Implementation.new
        key = :key
        result = imp.memorb_read(key)
        expect(result).to eq(nil)
      end
    end
  end
  describe '#memorb_has?' do
    context 'when a value has not been set' do
      it 'return false' do
        imp = Implementation.new
        result = imp.memorb_has?(:key)
        expect(result).to eq(false)
      end
    end
    context 'when a value has been set' do
      it 'returns true' do
        imp = Implementation.new
        key = :key
        cache = imp.instance_variable_get(:@memorb_cache)
        cache[[key]] = 'value'
        result = imp.memorb_has?(:key)
        expect(result).to be(true)
      end
    end
  end
  describe '#memorb_fetch' do
    context 'when a value has not been set' do
      it 'caches and returns the result of the block' do
        imp = Implementation.new
        key, value = :key, 'value'
        result = imp.memorb_fetch(key) { value }
        cache = imp.instance_variable_get(:@memorb_cache)
        expect(result).to equal(value)
      end
    end
    context 'when a value has been set' do
      it 'retrieves the value that was already set' do
        imp = Implementation.new
        key, value = :key, 'value'
        cache = imp.instance_variable_get(:@memorb_cache)
        cache[[key]] = value
        result = imp.memorb_fetch(key) { 'other' }
        expect(result).to equal(value)
      end
    end
  end
  describe '#memorb_forget' do
    it 'removes the cache entry for the given key' do
      imp = Implementation.new
      cache = imp.instance_variable_get(:@memorb_cache)
      original = { [:k1] => :v1, [:k2] => :v2 }
      addition = { [:k3] => :v3 }
      cache.merge!(original).merge!(addition)
      imp.memorb_forget(:k3)
      expect(cache).to eq(original)
    end
  end
end
