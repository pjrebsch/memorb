RSpec.describe Memorb::Cache do
  let(:klass) { Memorb::Cache }
  let(:store_mock) { instance_double(Memorb::KeyValueStore) }
  let(:integration) { BasicIntegration }
  let(:key) { :key }
  let(:value) { 'value' }
  subject { klass.new(integration: integration, store: store_mock) }

  describe '#initialize' do
    it 'takes an integration class' do
      cache = klass.new(integration: integration)
      expect(cache.integration).to equal(integration)
    end
    it 'can take a store' do
      cache = klass.new(integration: integration, store: store_mock)
      store = cache.instance_variable_get(:@store)
      expect(store).to equal(store_mock)
    end
    it 'can use its own store' do
      cache = klass.new(integration: integration)
      store = cache.instance_variable_get(:@store)
      expect(store).to be_an_instance_of(Memorb::KeyValueStore)
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
  describe '#register' do
    let(:integration) do
      Class.new(Counter) { include Memorb }
    end
    it 'caches the registered method' do
      cache = klass.new(integration: integration)
      cache.register(:increment)
      instance = integration.new
      result1 = instance.increment
      result2 = instance.increment
      expect(result1).to eq(result2)
    end
    context 'when registering a method multiple times' do
      it 'still caches the registered method' do
        cache = klass.new(integration: integration)
        cache.register(:increment)
        cache.register(:increment)
        instance = integration.new
        result1 = instance.increment
        result2 = instance.increment
        expect(result1).to eq(result2)
      end
    end
    context 'when registering a method that does not exist' do
      it 'still allows the method to be registered' do
        cache = klass.new(integration: integration)
        expect { cache.register(:undefined_method) }.not_to raise_error
      end
      it 'raises an error when trying to call it' do
        cache = klass.new(integration: integration)
        cache.register(:undefined_method)
        instance = integration.new
        expect { instance.undefined_method }.to raise_error(NoMethodError)
      end
    end
  end
  describe '#unregister' do
    let(:integration) do
      Class.new(Counter) { include Memorb }
    end
    it 'removes the override method for the given method' do
      cache = klass.new(integration: integration)
      cache.register(:increment)
      cache.unregister(:increment)
      mixin = Memorb::Mixin.for(integration)
      expect(mixin.public_instance_methods).not_to include(:increment)
    end
    context 'when there is no override method defined' do
      it 'does not raise an error' do
        cache = klass.new(integration: integration)
        expect { cache.unregister(:undefined_method!) }.not_to raise_error
      end
    end
    context 'when a method is registered multiple times' do
      it 'still unregisters the method' do
        cache = klass.new(integration: integration)
        cache.register(:increment)
        cache.register(:increment)
        cache.unregister(:increment)
        mixin = Memorb::Mixin.for(integration)
        expect(mixin.public_instance_methods).not_to include(:increment)
      end
    end
  end
end
