# frozen_string_literal: true

describe ::Memorb::IntegratorClassMethods do
  let(:integrator) { ::Class.new { extend ::Memorb } }
  let(:integration) { ::Memorb::Integration[integrator] }
  let(:instance) { integrator.new }

  describe '::memorb' do
    it 'returns the integration for the integrator' do
      expect(integrator.memorb).to be(integration)
    end
  end
  describe '::memorb!' do
    it 'calls register with the same arguments' do
      spy = double('spy', register: nil)
      mod = Module.new
      ::Memorb::RubyCompatibility.define_method(mod, :memorb) { spy }
      integrator.singleton_class.prepend(mod)
      block = Proc.new { nil }
      expect(spy).to receive(:register).with(:a, &block)
      integrator.memorb!(:a, &block)
    end
  end
  describe '::inherited' do
    it 'makes children of integrators get their own integration' do
      child_integrator = ::Class.new(integrator)
      integration = ::Memorb::Integration[child_integrator]
      expect(integration).not_to be(nil)
      expected_ancestry = [integration, child_integrator]
      expect(child_integrator.ancestors).to start_with(*expected_ancestry)
    end
  end
  describe '::method_added' do
    let(:method_name) { :method_1 }

    it 'retains upstream behavior' do
      spy = double('spy', spy!: nil)
      ::Memorb::RubyCompatibility
        .define_method(integrator.singleton_class, :method_added) do |m|
          spy.spy!(m)
        end
      expect(spy).to receive(:spy!).with(method_name)
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
    end
    context 'when the method has been registered' do
      it 'enables the method' do
        integration.register(method_name)
        expect(integration.enabled_methods).not_to include(method_name)
        expect(integration.public_instance_methods).not_to include(method_name)
        ::Memorb::RubyCompatibility
          .define_method(integrator, method_name) { nil }
        expect(integration.enabled_methods).to include(method_name)
        expect(integration.public_instance_methods).to include(method_name)
      end
    end
    context 'when automatic registration is enabled' do
      it 'registers and enables new methods' do
        integration.send(:_auto_registration).increment
        ::Memorb::RubyCompatibility
          .define_method(integrator, method_name) { nil }
        expect(integration.registered_methods).to include(method_name)
        expect(integration.enabled_methods).to include(method_name)
        expect(integration.public_instance_methods).to include(method_name)
      end
    end
  end
  describe '::method_removed' do
    let(:method_name) { :method_1 }
    let(:method_id) { ::Memorb::MethodIdentifier.new(method_name) }

    it 'retains upstream behavior' do
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      spy = double('spy', spy!: nil)
      ::Memorb::RubyCompatibility
        .define_method(integrator.singleton_class, :method_removed) do |m|
          spy.spy!(m)
        end
      expect(spy).to receive(:spy!).with(method_name)
      ::Memorb::RubyCompatibility.remove_method(integrator, method_name)
    end
    it 'removes the override for the method' do
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      integration.register(method_name)
      expect(integration.enabled_methods).to include(method_name)
      expect(integration.public_instance_methods).to include(method_name)
      ::Memorb::RubyCompatibility.remove_method(integrator, method_name)
      expect(integration.enabled_methods).not_to include(method_name)
      expect(integration.public_instance_methods).not_to include(method_name)
    end
    it 'clears cached data for the method in all instances' do
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      integration.register(method_name)
      instance.send(method_name)
      store = instance.memorb.method_store.read(method_id)
      expect(store.keys).not_to be_empty
      ::Memorb::RubyCompatibility.remove_method(integrator, method_name)
      expect(store.keys).to be_empty
    end
  end
  describe '::method_undefined' do
    let(:method_name) { :method_1 }
    let(:method_id) { ::Memorb::MethodIdentifier.new(method_name) }

    it 'retains upstream behavior' do
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      spy = double('spy', spy!: nil)
      ::Memorb::RubyCompatibility
        .define_method(integrator.singleton_class, :method_undefined) do |m|
          spy.spy!(m)
        end
      expect(spy).to receive(:spy!).with(method_name)
      ::Memorb::RubyCompatibility.undef_method(integrator, method_name)
    end
    it 'undefines the override for the method' do
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      integration.register(method_name)
      ::Memorb::RubyCompatibility.undef_method(integrator, method_name)
      instance = integrator.new
      expect(integration.enabled_methods).not_to include(method_name)
      expect(integration.public_instance_methods).not_to include(method_name)
      expect {
        instance.send(method_name)
      }.to raise_error(::NoMethodError, /undefined method/)
    end
    it 'clears cached data for the method in all instances' do
      ::Memorb::RubyCompatibility
        .define_method(integrator, method_name) { nil }
      integration.register(method_name)
      instance.send(method_name)
      store = instance.memorb.method_store.read(method_id)
      expect(store.keys).not_to be_empty
      ::Memorb::RubyCompatibility.undef_method(integrator, method_name)
      expect(store.keys).to be_empty
    end
  end
end
