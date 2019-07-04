RSpec.describe Memorb::Cache do
  let(:klass) { Memorb::Cache }
  let(:store_mock) { instance_double(Memorb::Store) }
  let(:key) { :key }
  let(:value) { 'value' }
  subject { klass.new(store: store_mock) }

  describe '#initialize' do
    it 'can take a store' do
      cache = klass.new(store: store_mock)
      store = cache.instance_variable_get(:@store)
      expect(store).to equal(store_mock)
    end
    it 'can use its own store' do
      cache = klass.new
      store = cache.instance_variable_get(:@store)
      expect(store).to be_an_instance_of(Memorb::Store)
    end
  end
  describe '#write' do
    it 'writes to the store' do
      expect(store_mock).to receive(:write).with([key], value)
      subject.write(key, value)
    end
  end
  describe '#read' do
    it 'reads from the store' do
      expect(store_mock).to receive(:read).with([key])
      subject.read(key)
    end
  end
  describe '#fetch' do
    it 'fetches from the store' do
      block = Proc.new { value }
      expect(store_mock).to receive(:fetch).with([key], &block)
      subject.fetch(key, &block)
    end
  end
  describe '#forget' do
    it 'forgets from the store' do
      expect(store_mock).to receive(:forget).with([key])
      subject.forget(key)
    end
  end
  describe '#reset!' do
    it 'resets the store' do
      expect(store_mock).to receive(:reset!)
      subject.reset!
    end
  end
end
