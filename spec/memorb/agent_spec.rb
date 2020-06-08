# frozen_string_literal: true

describe ::Memorb::Agent do
  let(:target) { ::SpecHelper.basic_target_class }
  let(:integrator) { ::Class.new(target) { extend ::Memorb } }
  let(:integrator_instance) { integrator.new }
  subject { described_class.new(integrator_instance.object_id) }

  describe '#id' do
    it 'returns the value provided upon initialization' do
      expect(subject.id).to equal(integrator_instance.object_id)
    end
  end
  describe '#method_store' do
    it 'returns a key-values store' do
      expect(subject.method_store).to be_an_instance_of(::Memorb::KeyValueStore)
    end
    context 'when called more than once' do
      it 'returns the same store each time' do
        store_1 = subject.method_store
        store_2 = subject.method_store
        expect(store_1).to be(store_2)
      end
    end
  end
  describe '#value_store' do
    it 'returns a key-values store' do
      expect(subject.value_store).to be_an_instance_of(::Memorb::KeyValueStore)
    end
    context 'when called more than once' do
      it 'returns the same store each time' do
        store_1 = subject.value_store
        store_2 = subject.value_store
        expect(store_1).to be(store_2)
      end
    end
  end
  describe '#fetch' do
    it 'delegates to the value store' do
      subject.fetch([:a, :b]) { :c }
      value = subject.value_store.read([:a, :b].hash)
      expect(value).to eq(:c)
    end
  end
end
