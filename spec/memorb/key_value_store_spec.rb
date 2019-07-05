RSpec.describe Memorb::KeyValueStore do
  let(:key) { :key }
  let(:value) { 'value' }

  describe '#write' do
    it 'stores a value' do
      subject.write(key, value)
      data = subject.instance_variable_get(:@data)
      expect(data).to include(key => value)
    end
    it 'returns the stored value' do
      result = subject.write(key, value)
      expect(result).to equal(value)
    end
  end
  describe '#read' do
    it 'retrieves a value for a given key' do
      data = subject.instance_variable_get(:@data)
      data[key] = value
      result = subject.read(key)
      expect(result).to equal(value)
    end
    context 'when a value has not been set' do
      it 'returns nil' do
        result = subject.read(key)
        expect(result).to eq(nil)
      end
    end
  end
  describe '#has?' do
    context 'when a value has not been set' do
      it 'return false' do
        result = subject.has?(:key)
        expect(result).to eq(false)
      end
    end
    context 'when a value has been set' do
      it 'returns true' do
        data = subject.instance_variable_get(:@data)
        data[key] = value
        result = subject.has?(:key)
        expect(result).to be(true)
      end
    end
  end
  describe '#fetch' do
    context 'when a value has not been set' do
      it 'caches and returns the result of the block' do
        result = subject.fetch(key) { value }
        expect(result).to equal(value)
        data = subject.instance_variable_get(:@data)
        expect(data[key]).to equal(value)
      end
    end
    context 'when a value has been set' do
      it 'retrieves the value that was already set' do
        data = subject.instance_variable_get(:@data)
        data[key] = value
        result = subject.fetch(key) { 'other' }
        expect(result).to equal(value)
      end
    end
  end
  describe '#forget' do
    it 'removes the cache entry for the given key' do
      data = subject.instance_variable_get(:@data)
      original = { :k1 => :v1, :k2 => :v2 }
      addition = { :k3 => :v3 }
      data.merge!(original).merge!(addition)
      subject.forget(:k3)
      expect(data).to eq(original)
    end
  end
  describe '#reset!' do
    it 'clears all data' do
      data = subject.instance_variable_get(:@data)
      data[key] = value
      subject.reset!
      expect(data).to be_empty
    end
  end
  describe '#inspect' do
    it 'displays the keys that it stores' do
      [:symbol, 'string', 123, [:a, :b]].each { |k| subject.write(k, value) }
      expectation = '#<Memorb::KeyValueStore keys=[:symbol, "string", 123, [:a, :b]]>'
      expect(subject.inspect).to eq(expectation)
    end
  end
end
