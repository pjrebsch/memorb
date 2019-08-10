RSpec.describe Memorb::Integration do
  let(:target) { Class.new(Counter) }

  describe '::integrate_with!' do
    it 'returns the integration for the given class' do
      result = described_class.integrate_with!(target)
      expect(result).not_to be(nil)
    end
    context 'when called more than once for a given class' do
      it 'returns the same integration every time' do
        result1 = described_class.integrate_with!(target)
        result2 = described_class.integrate_with!(target)
        expect(result1).to be(result2)
      end
      it 'includes the integration with the integrator only once' do
        described_class.integrate_with!(target)
        integration = described_class.integrate_with!(target)
        ancestors = target.ancestors
        integrations = ancestors.select { |a| a.equal? integration }
        expect(integrations).to match_array([integration])
      end
    end
  end
  describe '::[]' do
    it 'returns the integration for the given class' do
      integration = described_class.integrate_with!(target)
      result = described_class[target]
      expect(result).to be(integration)
    end
    context 'when given a class that has not been called with integrate!' do
      it 'returns nil' do
        result = described_class[target]
        expect(result).to be(nil)
      end
    end
  end

  describe 'an integration' do
    let(:integrator) { target.tap { |x| x.extend(Memorb) } }
    let(:integrator_singleton) { integrator.singleton_class }
    let(:instance) { integrator.new }
    subject { described_class[integrator] }

    describe '#initialize' do
      it 'retains its original behavior' do
        expect(instance.counter).to eq(123)
      end
    end
    describe '#memorb' do
      it 'returns the memorb cache' do
        cache = instance.memorb
        expect(cache).to be_an_instance_of(Memorb::Cache)
      end
      it 'does not share the cache across instances' do
        cache1 = integrator.new.memorb
        cache2 = integrator.new.memorb
        expect(cache1).not_to equal(cache2)
      end
    end
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
      it 'records the registration of the method' do
        subject.register(:increment)
        expect(subject.registered_methods).to include(:increment)
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
          subject.register(:undefined_method)
          expect(subject.registered_methods).to include(:undefined_method)
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
      it 'removes record of the registered method' do
        subject.register(:increment)
        subject.unregister(:increment)
        expect(subject.registered_methods).not_to include(:increment)
      end
      context 'when there is no override method defined' do
        it 'does not raise an error' do
          expect { subject.unregister(:undefined_method) }.not_to raise_error
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
    describe '::registered_methods' do
      it 'returns an array of registered methods' do
        methods = [:increment, :decrement]
        methods.each { |m| subject.register(m) }
        expect(subject.registered_methods).to match_array(methods)
      end
    end
    describe '::registered?' do
      context 'when the named method is registered' do
        it 'returns true' do
          subject.register(:increment)
          result = subject.registered?(:increment)
          expect(result).to be(true)
        end
      end
      context 'when the named method is not registered' do
        it 'returns false' do
          result = subject.registered?(:increment)
          expect(result).to be(false)
        end
      end
    end
    describe '::overridden_methods' do
      it 'returns an array of overridden methods' do
        methods = [:increment, :decrement]
        methods.each { |m| subject.send(:override!, m) }
        expect(subject.overridden_methods).to match_array(methods)
      end
    end
    describe '::overridden?' do
      context 'when the named method is overridden' do
        it 'returns true' do
          subject.send(:override!, :increment)
          result = subject.overridden?(:increment)
          expect(result).to be(true)
        end
      end
      context 'when the named method is not overridden' do
        it 'returns false' do
          result = subject.overridden?(:increment)
          expect(result).to be(false)
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
end
