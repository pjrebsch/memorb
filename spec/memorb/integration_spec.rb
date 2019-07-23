RSpec.describe Memorb::Integration do
  let(:integrator) { Class.new(Counter) { include Memorb } }
  let(:integrator_singleton) { integrator.singleton_class }
  subject { Memorb.integration(integrator) }

  describe '::integrator' do
    it 'returns its integrating class' do
      expect(subject.integrator).to be(integrator)
    end
  end
  describe '::name' do
    it 'includes the name of the integrating class' do
      name = 'IntegratingKlass'
      expectation = "Memorb:#{ name }"
      integrator_singleton.define_method(:name) { name }
      expect(subject.name).to eq(expectation)
    end
    context 'when integrating class does not have a name' do
      it 'uses the inspection of the integrating class' do
        expectation = "Memorb:#{ integrator.inspect }"
        integrator_singleton.define_method(:name) { nil }
        expect(subject.name).to eq(expectation)
        integrator_singleton.undef_method(:name)
        expect(subject.name).to eq(expectation)
      end
    end
    context 'when integrating class does not have an inspection' do
      it 'uses the object ID of the integrating class' do
        expectation = "Memorb:#{ integrator.object_id }"
        integrator_singleton.define_method(:inspect) { nil }
        expect(subject.name).to eq(expectation)
        integrator_singleton.undef_method(:inspect)
        expect(subject.name).to eq(expectation)
      end
    end
  end
  describe '::register' do
    it 'caches the registered method' do
      subject.register(:increment)
      instance = integrator.new
      result1 = instance.increment
      result2 = instance.increment
      expect(result1).to eq(result2)
    end
    context 'when registering a method multiple times' do
      it 'still caches the registered method' do
        subject.register(:increment)
        subject.register(:increment)
        instance = integrator.new
        result1 = instance.increment
        result2 = instance.increment
        expect(result1).to eq(result2)
      end
    end
    context 'when registering a method that does not exist' do
      it 'still allows the method to be registered' do
        expect { subject.register(:undefined_method) }.not_to raise_error
      end
      it 'responds to the method' do
        subject.register(:undefined_method)
        instance = integrator.new
        expect(instance).to respond_to(:undefined_method)
      end
      it 'raises an error when trying to call it' do
        subject.register(:undefined_method)
        instance = integrator.new
        expect { instance.undefined_method }.to raise_error(NoMethodError)
      end
    end
  end
  describe '::unregister' do
    it 'removes the override method for the given method' do
      subject.register(:increment)
      subject.unregister(:increment)
      expect(subject.public_instance_methods).not_to include(:increment)
    end
    context 'when there is no override method defined' do
      it 'does not raise an error' do
        expect { subject.unregister(:an_undefined_method!) }.not_to raise_error
      end
    end
    context 'when a method is registered multiple times' do
      it 'still unregisters the method' do
        subject.register(:increment)
        subject.register(:increment)
        subject.unregister(:increment)
        expect(subject.public_instance_methods).not_to include(:increment)
      end
    end
  end
  context 'when mixing in with another class' do
    let(:error) { Memorb::InvalidIntegrationError }

    it 'raises an error when using prepend' do
      integration = subject
      expect { Class.new { prepend integration } }.to raise_error(error)
    end
    it 'raises an error when using include' do
      integration = subject
      expect { Class.new { include integration } }.to raise_error(error)
    end
  end
end
