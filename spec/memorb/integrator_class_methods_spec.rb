# frozen_string_literal: true

RSpec.describe Memorb::IntegratorClassMethods do
  let(:integrator) { Class.new { extend Memorb } }
  let(:integration) { Memorb::Integration[integrator] }
  let(:instance) { integrator.new }

  describe '::memorb' do
    it 'returns the integration for the integrator' do
      expect(integrator.memorb).to be(integration)
    end
  end
  describe '::inherited' do
    it 'makes children of integrators get their own integration' do
      child_integrator = Class.new(integrator)
      integration = Memorb::Integration[child_integrator]
      expect(integration).not_to be(nil)
      expected_ancestry = [integration, child_integrator]
      expect(child_integrator.ancestors).to start_with(*expected_ancestry)
    end
  end
  describe '::method_added' do
    let(:method_name) { :method_1 }

    it 'retains upstream behavior' do
      spy = double('spy', spy!: nil)
      integrator.singleton_class.send(:define_method, :method_added) do |m|
        spy.spy!(m)
      end
      expect(spy).to receive(:spy!).with(method_name)
      integrator.send(:define_method, method_name) { nil }
    end
    context 'when the method has been registered' do
      it 'overrides the method' do
        integration.register(method_name)
        expect(integration.overridden_methods).not_to include(method_name)
        expect(integration.public_instance_methods).not_to include(method_name)
        integrator.send(:define_method, method_name) { nil }
        expect(integration.overridden_methods).to include(method_name)
        expect(integration.public_instance_methods).to include(method_name)
      end
    end
    context 'when automatic registration is enabled' do
      it 'registers and overrides new methods' do
        integration.auto_register = true
        integrator.send(:define_method, method_name) { nil }
        expect(integration.registered_methods).to include(method_name)
        expect(integration.overridden_methods).to include(method_name)
        expect(integration.public_instance_methods).to include(method_name)
      end
    end
  end
  describe '::method_removed' do
    let(:method_name) { :method_1 }
    let(:method_id) { Memorb::MethodIdentifier.new(method_name) }

    it 'retains upstream behavior' do
      integrator.send(:define_method, method_name) { nil }
      spy = double('spy', spy!: nil)
      integrator.singleton_class.send(:define_method, :method_removed) do |m|
        spy.spy!(m)
      end
      expect(spy).to receive(:spy!).with(method_name)
      integrator.send(:remove_method, method_name)
    end
    it 'removes the override for the method' do
      integrator.send(:define_method, method_name) { nil }
      integration.register(method_name)
      expect(integration.overridden_methods).to include(method_name)
      expect(integration.public_instance_methods).to include(method_name)
      integrator.send(:remove_method, method_name)
      expect(integration.overridden_methods).not_to include(method_name)
      expect(integration.public_instance_methods).not_to include(method_name)
    end
    it 'clears cached data for the method in all instances' do
      integrator.send(:define_method, method_name) { nil }
      integration.register(method_name)
      instance.send(method_name)
      store = instance.memorb.method_store.read(method_id)
      expect(store.keys).not_to be_empty
      integrator.send(:remove_method, method_name)
      expect(store.keys).to be_empty
    end
  end
  describe '::method_undefined' do
    let(:method_name) { :method_1 }
    let(:method_id) { Memorb::MethodIdentifier.new(method_name) }

    it 'retains upstream behavior' do
      integrator.send(:define_method, method_name) { nil }
      spy = double('spy', spy!: nil)
      integrator.singleton_class.send(:define_method, :method_undefined) do |m|
        spy.spy!(m)
      end
      expect(spy).to receive(:spy!).with(method_name)
      integrator.send(:undef_method, method_name)
    end
    it 'undefines the override for the method' do
      integrator.send(:define_method, method_name) { nil }
      integration.register(method_name)
      integrator.send(:undef_method, method_name)
      instance = integrator.new
      expect(integration.overridden_methods).not_to include(method_name)
      expect(integration.public_instance_methods).not_to include(method_name)
      expect {
        instance.send(method_name)
      }.to raise_error(NoMethodError, /undefined method/)
    end
    it 'clears cached data for the method in all instances' do
      integrator.send(:define_method, method_name) { nil }
      integration.register(method_name)
      instance.send(method_name)
      store = instance.memorb.method_store.read(method_id)
      expect(store.keys).not_to be_empty
      integrator.send(:undef_method, method_name)
      expect(store.keys).to be_empty
    end
  end
end
