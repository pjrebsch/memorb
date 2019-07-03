RSpec.describe Memorb::InstanceMethods do
  let(:implementation) { Implementation.new }
  describe '#memorb?' do
    it 'returns true' do
      expect(implementation.memorb?).to be(true)
    end
  end
  describe '#memorb_reset!' do
    it 'resets the memorb cache' do
      cache1 = implementation.instance_variable_get(:@memorb_cache)
      implementation.memorb_reset!
      cache2 = implementation.instance_variable_get(:@memorb_cache)
      expect(cache1).not_to equal(cache2)
      expect(cache2).to eq(Memorb::Core.fresh_cache)
    end
  end
  describe '#memorb_write' do
    it 'stores a value in the cache' do
      key, value = :key, 'value'
      implementation.memorb_write(key, value)
      cache = implementation.instance_variable_get(:@memorb_cache)
      expect(cache).to include([key] => value)
    end
    it 'accepts multiple arguments as the key' do
      key, value = [:k1, :k2, :k3], 'value'
      implementation.memorb_write(*key, value)
      cache = implementation.instance_variable_get(:@memorb_cache)
      expect(cache).to include(key => value)
    end
    it 'returns the value' do
      key, value = :key, 'value'
      result = implementation.memorb_write(key, value)
      expect(result).to equal(value)
    end
  end
  describe '#memorb_read' do
    it 'retrieves a value from the cache' do
      key, value = :key, 'value'
      cache = implementation.instance_variable_get(:@memorb_cache)
      cache[[key]] = value
      result = implementation.memorb_read(key)
      expect(result).to equal(value)
    end
    context 'when a value has not been set' do
      it 'returns nil' do
        key = :key
        result = implementation.memorb_read(key)
        expect(result).to eq(nil)
      end
    end
  end
  describe '#memorb_has?' do
    context 'when a value has not been set' do
      it 'return false' do
        result = implementation.memorb_has?(:key)
        expect(result).to eq(false)
      end
    end
    context 'when a value has been set' do
      it 'returns true' do
        key = :key
        cache = implementation.instance_variable_get(:@memorb_cache)
        cache[[key]] = 'value'
        result = implementation.memorb_has?(:key)
        expect(result).to be(true)
      end
    end
  end
  describe '#memorb_fetch' do
    context 'when a value has not been set' do
      it 'caches and returns the result of the block' do
        key, value = :key, 'value'
        result = implementation.memorb_fetch(key) { value }
        cache = implementation.instance_variable_get(:@memorb_cache)
        expect(result).to equal(value)
      end
    end
    context 'when a value has been set' do
      it 'retrieves the value that was already set' do
        key, value = :key, 'value'
        cache = implementation.instance_variable_get(:@memorb_cache)
        cache[[key]] = value
        result = implementation.memorb_fetch(key) { 'other' }
        expect(result).to equal(value)
      end
    end
  end
  describe '#memorb_forget' do
    it 'removes the cache entry for the given key' do
      cache = implementation.instance_variable_get(:@memorb_cache)
      original = { [:k1] => :v1, [:k2] => :v2 }
      addition = { [:k3] => :v3 }
      cache.merge!(original).merge!(addition)
      implementation.memorb_forget(:k3)
      expect(cache).to eq(original)
    end
  end
end
