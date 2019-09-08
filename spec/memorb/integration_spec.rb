# frozen_string_literal: true

RSpec.describe Memorb::Integration do
  let(:target) { SpecHelper.basic_target_class }

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
  describe '::integrated?' do
    context 'when a given class has not integrated Memorb' do
      it 'returns false' do
        result = described_class.integrated?(target)
        expect(result).to be(false)
      end
    end
    context 'when a given class has integrated with Memorb' do
      it 'returns true' do
        described_class.integrate_with!(target)
        result = described_class.integrated?(target)
        expect(result).to be(true)
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
    let(:cache_registry) { subject.singleton_class.const_get(:CACHES) }
    subject { described_class[integrator] }

    describe 'integrator instance methods' do
      describe '#initialize' do
        it 'retains the behavior of the instance' do
          expect(instance.counter).to be(0)
        end
        it 'initializes the cache with the object ID of the instance' do
          cache = instance.memorb
          expect(cache.id).to equal(instance.object_id)
        end
        it 'sets the cache to an instance variable named based on the instance' do
          var_name = :"@memorb_#{ '%016x' % (instance.object_id << 1) }"
          expect(instance.instance_variables).to include(var_name)
        end
        it 'adds the cache to the global registry' do
          cache = instance.memorb
          expect(cache_registry.keys).to match_array([cache.id])
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
    end
    describe '::integrator' do
      it 'returns its integrating class' do
        expect(subject.integrator).to be(integrator)
      end
    end
    describe '::register' do
      shared_examples '::register' do |provided_name|
        let(:method_name) { :increment }

        it 'caches the registered method' do
          subject.register(provided_name)
          result1 = instance.send(method_name)
          result2 = instance.send(method_name)
          expect(result1).to eq(result2)
        end
        it 'records the registration of the method' do
          subject.register(provided_name)
          expect(subject.registered_methods).to include(method_name)
        end
        context 'when registering a method multiple times' do
          it 'still caches the registered method' do
            2.times { subject.register(provided_name) }
            result1 = instance.send(method_name)
            result2 = instance.send(method_name)
            expect(result1).to eq(result2)
          end
        end
        context 'when registering a method that does not exist' do
          let(:target) { Class.new }

          it 'still allows the method to be registered' do
            subject.register(provided_name)
            expect(subject.registered_methods).to include(method_name)
          end
          it 'does not override the method' do
            subject.register(provided_name)
            expect(subject.overridden_methods).not_to include(method_name)
          end
          it 'an integrator instance does not respond to the method' do
            subject.register(provided_name)
            expect(instance).not_to respond_to(method_name)
          end
          it 'raises an error when trying to call it' do
            subject.register(provided_name)
            expect { instance.send(method_name) }.to raise_error(NoMethodError)
          end
          context 'once the method is defined' do
            it 'responds to the the method' do
              subject.register(provided_name)
              integrator.define_method(method_name) { nil }
              expect(instance).to respond_to(method_name)
            end
          end
        end
      end
      context 'with method name supplied as a symbol' do
        it_behaves_like '::register', :increment
      end
      context 'with method name supplied as a string' do
        it_behaves_like '::register', 'increment'
      end
    end
    describe '::registered?' do
      it 'preserves the visibility of the method that it overrides' do
        visibilities = [:public, :protected, :private]
        method_names = visibilities.map { |vis| :"#{ vis }_method" }

        integrator = Class.new.tap do |target|
          eval_string = visibilities.map.with_index do |vis, i|
            "#{ vis }; def #{ method_names[i] }; end;"
          end.join("\n")
          target.class_eval(eval_string)
          target.extend(Memorb)
        end

        subject = described_class[integrator]

        method_names.each do |m|
          subject.register(m)
        end

        visibilities.each.with_index do |vis, i|
          overrides = subject.send(:"#{ vis }_instance_methods", false)
          expect(overrides).to include(method_names[i])
          other_methods = method_names.reject { |m| m === method_names[i] }
          expect(overrides).not_to include(*other_methods)
        end
      end
      shared_examples '::registered?' do |provided_name|
        let(:method_name) { :increment }

        context 'when the named method is registered' do
          it 'returns true' do
            subject.register(method_name)
            result = subject.registered?(provided_name)
            expect(result).to be(true)
          end
        end
        context 'when the named method is not registered' do
          it 'returns false' do
            result = subject.registered?(provided_name)
            expect(result).to be(false)
          end
        end
      end
      context 'with method name supplied as a symbol' do
        it_behaves_like '::registered?', :increment
      end
      context 'with method name supplied as a string' do
        it_behaves_like '::registered?', 'increment'
      end
    end
    describe '::enable' do
      shared_examples '::enable' do |provided_name|
        let(:method_name) { :increment }

        context 'when the method is registered' do
          it 'overrides the method' do
            subject.register(method_name)
            subject.disable(method_name)
            subject.enable(provided_name)
            expect(subject.overridden_methods).to include(method_name)
          end
          it 'returns the visibility of the method' do
            subject.register(method_name)
            result = subject.enable(provided_name)
            expect(result).to be(:public)
          end
          context 'when the method is not defined' do
            let(:target) { Class.new }

            it 'does not override the method' do
              subject.register(method_name)
              subject.enable(provided_name)
              expect(subject.overridden_methods).not_to include(method_name)
            end
            it 'returns nil' do
              subject.register(method_name)
              result = subject.enable(provided_name)
              expect(result).to be(nil)
            end
          end
        end
        context 'when the method is not registered' do
          it 'does not override the method' do
            subject.enable(provided_name)
            expect(subject.overridden_methods).not_to include(method_name)
          end
          it 'returns nil' do
            result = subject.enable(provided_name)
            expect(result).to be(nil)
          end
        end
      end
      context 'with method name supplied as a symbol' do
        it_behaves_like '::enable', :increment
      end
      context 'with method name supplied as a string' do
        it_behaves_like '::enable', 'increment'
      end
    end
    describe '::disable' do
      shared_examples '::disable' do |provided_name|
        let(:method_name) { :increment }

        it 'removes the override method for the given method' do
          subject.register(method_name)
          subject.disable(provided_name)
          expect(subject.overridden_methods).not_to include(method_name)
        end
        context 'when there is no override method defined' do
          let(:target) { Class.new }

          it 'does not raise an error' do
            expect { subject.disable(provided_name) }.not_to raise_error
          end
        end
      end
      context 'with method name supplied as a symbol' do
        it_behaves_like '::disable', :increment
      end
      context 'with method name supplied as a string' do
        it_behaves_like '::disable', 'increment'
      end
    end
    describe '::registered_methods' do
      it 'returns an array of registered methods' do
        methods = [:increment, :decrement]
        methods.each { |m| subject.register(m) }
        expect(subject.registered_methods).to match_array(methods)
      end
    end
    describe '::overridden_methods' do
      it 'returns an array of overridden methods' do
        methods = [:increment, :double]
        methods.each { |m| subject.register(m) }
        expect(subject.overridden_methods).to match_array(methods)
      end
    end
    describe '::overridden?' do
      shared_examples '::overridden?' do |provided_name|
        let(:method_name) { :increment }

        context 'when the named method is overridden' do
          it 'returns true' do
            subject.register(method_name)
            result = subject.overridden?(provided_name)
            expect(result).to be(true)
          end
        end
        context 'when the named method is not overridden' do
          it 'returns false' do
            result = subject.overridden?(provided_name)
            expect(result).to be(false)
          end
        end
      end
      context 'with method name supplied as a symbol' do
        it_behaves_like '::overridden?', :increment
      end
      context 'with method name supplied as a string' do
        it_behaves_like '::overridden?', 'increment'
      end
    end
    describe '::purge' do
      let(:method_name) { :increment }
      let(:method_id) { Memorb::MethodIdentifier.new(method_name) }

      it 'clears cached data for the given method in all instances' do
        subject.register(method_name)
        instance.send(method_name)
        store = instance.memorb.read(method_id)
        expect(store.keys).not_to be_empty
        subject.purge(method_name)
        expect(store.keys).to be_empty
      end
      context 'when the given method has no cache record' do
        it 'does not raise an error' do
          subject.register(method_name)
          store = instance.memorb.read(method_id)
          expect(store).to be(nil)
          expect { subject.purge(method_name) }.not_to raise_error
        end
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
    describe '::create_cache' do
      it 'returns a cache object' do
        cache = subject.create_cache(instance)
        expect(cache).to be_an_instance_of(::Memorb::Cache)
      end
      it 'writes the cache to the global cache registry' do
        cache = subject.create_cache(instance)
        registry = subject.singleton_class.const_get(:CACHES)
        expect(registry.keys).to match_array([cache.id])
      end
    end
    it 'supports regularly invalid method names' do
      method_name = :' 1!2@3#4$5%6^7&8*9(0),\./=<+>-??'
      subject.register(method_name)
      integrator.define_method(method_name) { nil }
      expect(subject.registered_methods).to include(method_name)
      expect(subject.overridden_methods).to include(method_name)
      expect { instance.send(method_name) }.not_to raise_error
    end
    context 'when mixing in with another class' do
      let(:error) { Memorb::InvalidIntegrationError }
      let(:klass) { Class.new.singleton_class }

      it 'raises an error when using prepend' do
        expect { klass.prepend(subject) }.to raise_error(error)
      end
      it 'raises an error when using include' do
        expect { klass.include(subject) }.to raise_error(error)
      end
    end
    context 'when freed by the garbage collector' do
      it 'removes its cache from the global registry' do
        # At the time of writing, RSpec blocks aren't allowing out-of-scope
        # variables to be garbage collected, so `WeakRef` is used to fix that.
        require 'weakref'
        ref = WeakRef.new(integrator.new)
        cache = ref.__getobj__.memorb
        expect(cache_registry.keys).to include(cache.id)
        SpecHelper.force_garbage_collection
        expect(cache_registry.keys).to be_empty
      end
    end
  end
end
