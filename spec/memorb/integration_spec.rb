# frozen_string_literal: true

describe ::Memorb::Integration do
  let(:target) { ::SpecHelper.basic_target_class }

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
        expect(integrations).to contain_exactly(integration)
      end
    end
    context 'when given a regular object' do
      it 'raises an error' do
        obj = ::Object.new
        error = ::Memorb::InvalidIntegrationError
        error_message = 'integration target must be a class'
        expect { obj.extend(::Memorb) }.to raise_error(error, error_message)
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
    let(:integrator) { target.tap { |x| x.extend(::Memorb) } }
    let(:integrator_singleton) { integrator.singleton_class }
    let(:instance) { integrator.new }
    let(:agent_registry) { subject.send(:_agents) }
    subject { described_class[integrator] }

    describe 'integrator instance methods' do
      describe '#initialize' do
        it 'retains the behavior of the instance' do
          expect(instance.counter).to be(0)
        end
        it 'initializes the agent with the object ID of the instance' do
          agent = instance.memorb
          expect(agent.id).to equal(instance.object_id)
        end
        it 'adds the agent to the global registry' do
          agent = instance.memorb
          expect(agent_registry.keys).to contain_exactly(agent.id)
        end
      end
      describe '#memorb' do
        it 'returns the agent for the instance' do
          agent = instance.memorb
          expect(agent).to be_an_instance_of(::Memorb::Agent)
        end
        it 'does not share the agent across instances' do
          agent_1 = integrator.new.memorb
          agent_2 = integrator.new.memorb
          expect(agent_1).not_to equal(agent_2)
        end
      end
    end
    describe '::integrator' do
      it 'returns its integrating class' do
        expect(subject.integrator).to be(integrator)
      end
    end
    describe '::register' do
      let(:method_name) { :increment }

      context 'when called with a single argument' do
        it 'caches the registered method' do
          subject.register(method_name)
          result1 = instance.send(method_name)
          result2 = instance.send(method_name)
          expect(result1).to eq(result2)
        end
        it 'records the registration of the method' do
          subject.register(method_name)
          expect(subject.registered_methods).to include(method_name)
        end
        context 'when registering a method multiple times' do
          it 'still caches the registered method' do
            2.times { subject.register(method_name) }
            result1 = instance.send(method_name)
            result2 = instance.send(method_name)
            expect(result1).to eq(result2)
          end
        end
        context 'when registering a method that does not exist' do
          let(:target) { ::Class.new }

          it 'still allows the method to be registered' do
            subject.register(method_name)
            expect(subject.registered_methods).to include(method_name)
          end
          it 'does not enable the method' do
            subject.register(method_name)
            expect(subject.enabled_methods).not_to include(method_name)
          end
          it 'an integrator instance does not respond to the method' do
            subject.register(method_name)
            expect(instance).not_to respond_to(method_name)
          end
          it 'raises an error when trying to call it' do
            subject.register(method_name)
            expect { instance.send(method_name) }.to raise_error(::NoMethodError)
          end
          context 'once the method is defined' do
            it 'responds to the the method' do
              subject.register(method_name)
              ::Memorb::RubyCompatibility
                .define_method(integrator, method_name) { nil }
              expect(instance).to respond_to(method_name)
            end
          end
        end
      end
      context 'when called with only a block' do
        it 'adds the methods defined in the block to the integrator' do
          subject.register do
            def method_1; end
            def method_2; end
          end
          methods = integrator.public_instance_methods(false)
          expect(methods).to include(:method_1, :method_2)
        end
        it 'registers and enables the methods defined in that block' do
          subject.register do
            def method_1; end
            def method_2; end
          end
          expect(subject.registered_methods).to include(:method_1, :method_2)
          expect(subject.enabled_methods).to include(:method_1, :method_2)
        end
        context 'when an error is raised in the provided block' do
          it 'still disables automatic registration' do
            begin
              subject.register { raise }
            rescue ::RuntimeError
            end
            expect(subject.auto_register?).to be(false)
          end
        end
      end
      context 'when called with arguments and a block' do
        it 'raises an error' do
          expect {
            subject.register(:method_1) { nil }
          }.to raise_error(::ArgumentError)
        end
      end
      context 'when called without arguments or a block' do
        it 'raises an error' do
          expect { subject.register }.to raise_error(::ArgumentError)
        end
      end
    end
    describe '::registered?' do
      it 'preserves the visibility of the method that it overrides' do
        visibilities = [:public, :protected, :private]
        method_names = visibilities.map { |vis| :"#{ vis }_method" }

        integrator = ::Class.new.tap do |target|
          eval_string = visibilities.map.with_index do |vis, i|
            "#{ vis }; def #{ method_names[i] }; end;"
          end.join("\n")
          target.class_eval(eval_string)
          target.extend(::Memorb)
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

        it 'records the cache key correctly' do
          method_id = ::Memorb::MethodIdentifier.new(provided_name)
          subject.register(method_name)
          instance.send(method_name)
          store = instance.memorb.method_store
          expect(store.keys).to contain_exactly(method_id)
        end
        context 'when the method is registered' do
          it 'overrides the method' do
            subject.register(method_name)
            subject.disable(method_name)
            subject.enable(provided_name)
            expect(subject.enabled_methods).to include(method_name)
          end
          it 'returns the visibility of the method' do
            subject.register(method_name)
            result = subject.enable(provided_name)
            expect(result).to be(:public)
          end
          context 'when the method is not defined' do
            let(:target) { ::Class.new }

            it 'does not override the method' do
              subject.register(method_name)
              subject.enable(provided_name)
              expect(subject.enabled_methods).not_to include(method_name)
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
            expect(subject.enabled_methods).not_to include(method_name)
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
          expect(subject.enabled_methods).not_to include(method_name)
        end
        context 'when there is no override method defined' do
          let(:target) { ::Class.new }

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
    describe '::enabled_methods' do
      it 'returns an array of enabled methods' do
        methods = [:increment, :double]
        methods.each { |m| subject.register(m) }
        expect(subject.enabled_methods).to match_array(methods)
      end
    end
    describe '::disabled_methods' do
      it 'returns an array of methods that are not enabled' do
        methods = [:a, :increment, :b, :double, :c]
        methods.each { |m| subject.register(m) }
        expect(subject.disabled_methods).to contain_exactly(:a, :b, :c)
      end
    end
    describe '::enabled?' do
      shared_examples '::enabled?' do |provided_name|
        let(:method_name) { :increment }

        context 'when the named method is enabled' do
          it 'returns true' do
            subject.register(method_name)
            result = subject.enabled?(provided_name)
            expect(result).to be(true)
          end
        end
        context 'when the named method is not enabled' do
          it 'returns false' do
            result = subject.enabled?(provided_name)
            expect(result).to be(false)
          end
        end
      end
      context 'with method name supplied as a symbol' do
        it_behaves_like '::enabled?', :increment
      end
      context 'with method name supplied as a string' do
        it_behaves_like '::enabled?', 'increment'
      end
    end
    describe '::purge' do
      let(:method_name) { :increment }
      let(:method_id) { ::Memorb::MethodIdentifier.new(method_name) }

      it 'clears cached data for the given method in all instances' do
        subject.register(method_name)
        instance.send(method_name)
        store = instance.memorb.method_store.read(method_id)
        expect(store.keys).not_to be_empty
        subject.purge(method_name)
        expect(store.keys).to be_empty
      end
      context 'when the given method has no cache record' do
        it 'does not raise an error' do
          subject.register(method_name)
          store = instance.memorb.method_store.read(method_id)
          expect(store).to be(nil)
          expect { subject.purge(method_name) }.not_to raise_error
        end
      end
    end
    describe '::auto_register?' do
      context 'by default' do
        it 'returns false' do
          expect(subject.auto_register?).to be(false)
        end
      end
      context 'when turned on' do
        it 'returns true' do
          subject.send(:_auto_registration).increment
          expect(subject.auto_register?).to be(true)
        end
      end
    end
    describe '::auto_register!' do
      context 'when not given a block' do
        it 'raises an error' do
          expect {
            subject.auto_register!
          }.to raise_error(::ArgumentError, 'a block must be provided')
        end
      end
      it 'enables automatic registration of methods defined in the block' do
        subject.auto_register! do
          ::Memorb::RubyCompatibility.define_method(integrator, :a) { nil }
        end
        expect(subject.registered_methods).to include(:a)
      end
      it 'returns the return value of the given block' do
        result = subject.auto_register! { 1 }
        expect(result).to be(1)
      end
      context 'when an error is raised in the given block' do
        it 'still disables automatic registration' do
          begin
            subject.auto_register! { raise }
          rescue ::RuntimeError
          end
          expect(subject.auto_register?).to be(false)
        end
        it 'returns nil' do
          begin
            result = subject.auto_register! { raise }
          rescue ::RuntimeError
          end
          expect(result).to be(nil)
        end
      end
      context 'when nested' do
        it 'preserves the setting until the outer block ends' do
          subject.auto_register! do
            subject.auto_register! do
              nil
            end
            expect(subject.auto_register?).to be(true)
          end
        end
      end
      context 'if the internal counter goes below zero' do
        it 'be corrected on subsequent calls' do
          subject.send(:_auto_registration).decrement
          subject.auto_register! do
            expect(subject.auto_register?).to be(true)
          end
        end
      end
    end
    describe '::name' do
      it 'includes the name of the integrating class' do
        name = 'IntegratingKlass'
        expectation = "Memorb:#{ name }"
        ::Memorb::RubyCompatibility
          .define_method(integrator_singleton, :name) { name }
        expect(subject.name).to eq(expectation)
      end
      context 'when integrating class does not have a name' do
        it 'uses the inspection of the integrating class' do
          expectation = "Memorb:#{ integrator.inspect }"
          ::Memorb::RubyCompatibility
            .define_method(integrator_singleton, :name) { nil }
          expect(subject.name).to eq(expectation)
          ::Memorb::RubyCompatibility.undef_method(integrator_singleton, :name)
          expect(subject.name).to eq(expectation)
        end
      end
      context 'when integrating class does not have an inspection' do
        it 'uses the object ID of the integrating class' do
          expectation = "Memorb:#{ integrator.object_id }"
          ::Memorb::RubyCompatibility
            .define_method(integrator_singleton, :inspect) { nil }
          expect(subject.name).to eq(expectation)
          ::Memorb::RubyCompatibility.undef_method(integrator_singleton, :inspect)
          expect(subject.name).to eq(expectation)
        end
      end
    end
    describe '::create_agent' do
      it 'returns a agent object' do
        agent = subject.create_agent(instance)
        expect(agent).to be_an_instance_of(::Memorb::Agent)
      end
      it 'writes the agent to the global agent registry' do
        agent = subject.create_agent(instance)
        registry = subject.send(:_agents)
        expect(registry.keys).to contain_exactly(agent.id)
      end
    end
    it 'supports regularly invalid method names' do
      invalid_starting_chars = [0x00..0x40, 0x5b..0x60, 0x7b..0xff]
      method_name = invalid_starting_chars
        .map(&:to_a)
        .flatten
        .map(&:chr)
        .shuffle(random: ::SpecHelper.rng)
        .join
        .to_sym
      subject.register(method_name)
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      expect(subject.registered_methods).to include(method_name)
      expect(subject.enabled_methods).to include(method_name)
      expect { instance.send(method_name) }.not_to raise_error
    end
    context 'when prepending on another class' do
      it 'raises an error' do
        klass = ::Class.new.singleton_class
        error = ::Memorb::MismatchedTargetError
        expect { klass.prepend(subject) }.to raise_error(error)
      end
    end
    context 'when including with any class' do
      it 'raises an error' do
        klass = subject.integrator
        error = ::Memorb::InvalidIntegrationError
        error_message = 'an integration must be applied with `prepend`, not `include`'
        expect { klass.include(subject) }.to raise_error(error, error_message)
      end
    end
    # JRuby garbage collection isn't as straightforward as CRuby, so tests
    # that rely on garbage collection are skipped.
    if ::RUBY_ENGINE != 'jruby'
      context 'when freed by the garbage collector' do
        it 'removes its agent from the global registry' do
          # At the time of writing, RSpec blocks aren't allowing out-of-scope
          # variables to be garbage collected, so `WeakRef` is used to fix that.
          require 'weakref'
          ref = ::WeakRef.new(integrator.new)
          agent = ref.__getobj__.memorb
          expect(agent_registry.keys).to include(agent.id)
          ::SpecHelper.force_garbage_collection
          expect(agent_registry.keys).to be_empty
        end
      end
    end
  end
end
