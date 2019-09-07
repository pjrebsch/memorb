# frozen_string_literal: true

RSpec.describe Memorb::Cache do
  let(:target) { SpecHelper.basic_target_class }
  let(:integrator) { Class.new(target) { extend Memorb } }
  let(:integrator_instance) { integrator.new }
  let(:store) { instance_double(Memorb::KeyValueStore) }
  let(:key) { :key }
  let(:value) { 'value' }
  subject {
    described_class.new(integrator_instance.object_id).tap { |x|
      x.instance_variable_set(:@store, store)
    }
  }

  describe '#id' do
    it 'returns the value provided upon initialization' do
      expect(subject.id).to equal(integrator_instance.object_id)
    end
  end
  describe '#write' do
    it 'writes to the store' do
      expect(store).to receive(:write).with(key, value)
      subject.write(key, value)
    end
  end
  describe '#read' do
    it 'reads from the store' do
      expect(store).to receive(:read).with(key)
      subject.read(key)
    end
  end
  describe '#has?' do
    it 'checks with the store' do
      expect(store).to receive(:has?).with(key)
      subject.has?(key)
    end
  end
  describe '#fetch' do
    it 'fetches from the store' do
      block = Proc.new { value }
      expect(store).to receive(:fetch).with(key, &block)
      subject.fetch(key, &block)
    end
  end
  describe '#forget' do
    it 'forgets from the store' do
      expect(store).to receive(:forget).with(key)
      subject.forget(key)
    end
  end
  describe '#reset!' do
    it 'resets the store' do
      expect(store).to receive(:reset!)
      subject.reset!
    end
  end
  describe '#inspect' do
    it 'does not include information about its internals' do
      expect(subject.inspect).to match(/#<Memorb::Cache:0x\h+>/)
    end
  end
end
