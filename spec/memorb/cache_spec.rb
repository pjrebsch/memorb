RSpec.describe Memorb::Cache do
  let(:klass) { Memorb::Cache }
  let(:integrator) { Class.new(Counter) { include Memorb } }
  let(:store) { instance_double(Memorb::KeyValueStore) }
  let(:integration) { double(register: nil, unregister: nil) }
  let(:key) { :key }
  let(:value) { 'value' }
  subject {
    klass.new(integrator: integrator).tap { |x|
      x.instance_variable_set(:@store, store)
      x.instance_variable_set(:@integration, integration)
    }
  }

  describe '#initialize' do
    it 'takes an integrator' do
      cache = klass.new(integrator: integrator)
      expect(cache.integrator).to equal(integrator)
    end
  end
  describe '#write' do
    it 'writes to the store' do
      expect(store).to receive(:write).with([key], value)
      subject.write(key, value)
    end
  end
  describe '#read' do
    it 'reads from the store' do
      expect(store).to receive(:read).with([key])
      subject.read(key)
    end
  end
  describe '#fetch' do
    it 'fetches from the store' do
      block = Proc.new { value }
      expect(store).to receive(:fetch).with([key], &block)
      subject.fetch(key, &block)
    end
  end
  describe '#forget' do
    it 'forgets from the store' do
      expect(store).to receive(:forget).with([key])
      subject.forget(key)
    end
  end
  describe '#reset!' do
    it 'resets the store' do
      expect(store).to receive(:reset!)
      subject.reset!
    end
  end
  describe '#register' do
    it 'calls register on the integration' do
      method_name = :increment
      expect(integration).to receive(:register).with(method_name)
      subject.register(method_name)
    end
  end
  describe '#unregister' do
    it 'calls unregister on the integration' do
      method_name = :increment
      expect(integration).to receive(:unregister).with(method_name)
      subject.unregister(method_name)
    end
  end
  describe '#inspect' do
    it 'does not include information about its internals' do
      expect(subject.inspect).to match(/#<Memorb::Cache:0x\h+>/)
    end
  end
end
