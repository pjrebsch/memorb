RSpec.describe Memorb::Cache do
  let(:klass) { Memorb::Cache }
  let(:store_mock) { instance_double(Memorb::KeyValueStore) }
  let(:integration) { BasicIntegration }
  let(:mixin) { instance_double(Memorb::Mixin::MixinClassMethods) }
  let(:key) { :key }
  let(:value) { 'value' }
  subject { klass.new(integration: integration, store: store_mock) }

  describe '#initialize' do
    it 'takes an integration class' do
      cache = klass.new(integration: integration)
      expect(cache.integration).to equal(integration)
    end
    it 'can take a mixin' do
      cache = klass.new(integration: integration, mixin: mixin)
      expect(cache.mixin).to equal(mixin)
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
    it 'calls register on the mixin' do
      integration = Class.new(Counter) { include Memorb }
      cache = klass.new(integration: integration, mixin: mixin)
      method_name = :increment
      expect(mixin).to receive(:register).with(method_name)
      cache.register(method_name)
    end
  end
  describe '#unregister' do
    it 'calls unregister on the mixin' do
      integration = Class.new(Counter) { include Memorb }
      cache = klass.new(integration: integration, mixin: mixin)
      method_name = :increment
      expect(mixin).to receive(:unregister).with(method_name)
      cache.unregister(method_name)
    end
  end
  describe '#inspect' do
    it 'does not include information about its internals' do
      expect(subject.inspect).to match(/#<Memorb::Cache:0x\h+>/)
    end
  end
end
