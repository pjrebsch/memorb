RSpec.describe Memorb::IntegratorClassMethods do
  let(:integrator) { Class.new { extend Memorb } }
  let(:integration) { Memorb::Integration[integrator] }

  describe '::inherited' do
    it 'makes children of integrators get their own integration' do
      child_integrator = Class.new(integrator)
      integration = Memorb::Integration[child_integrator]
      expect(integration).not_to be(nil)
      expected_ancestry = [integration, child_integrator]
      expect(child_integrator.ancestors).to start_with(*expected_ancestry)
    end
  end
  describe '::memorb' do
    it 'returns the integration for the integrator' do
      expect(integrator.memorb).to be(integration)
    end
  end
  describe '::method_added' do
    let(:method_name) { :method_1 }

    it 'retains upstream behavior' do
      spy = double('spy', spy!: nil)
      integrator.singleton_class.define_method(:method_added) do |m|
        spy.spy!(m)
      end
      expect(spy).to receive(:spy!).with(method_name)
      integrator.define_method(method_name) { nil }
    end
    context 'when the method has been registered' do
      it 'overrides the method' do
        integration.register(method_name)
        expect(integration.overridden_methods).not_to include(method_name)
        expect(integration.public_instance_methods).not_to include(method_name)
        integrator.define_method(method_name) { nil }
        expect(integration.overridden_methods).to include(method_name)
        expect(integration.public_instance_methods).to include(method_name)
      end
    end
  end
  describe '::method_removed' do
    let(:method_name) { :method_1 }

    it 'retains upstream behavior' do
      integrator.define_method(method_name) { nil }
      spy = double('spy', spy!: nil)
      integrator.singleton_class.define_method(:method_removed) do |m|
        spy.spy!(m)
      end
      expect(spy).to receive(:spy!).with(method_name)
      integrator.remove_method(method_name)
    end
    context 'when the method has been registered' do
      it 'removes the override for the method' do
        integrator.define_method(method_name) { nil }
        integration.register(method_name)
        expect(integration.overridden_methods).to include(method_name)
        expect(integration.public_instance_methods).to include(method_name)
        integrator.remove_method(method_name)
        expect(integration.overridden_methods).not_to include(method_name)
        expect(integration.public_instance_methods).not_to include(method_name)
      end
    end
  end
end
