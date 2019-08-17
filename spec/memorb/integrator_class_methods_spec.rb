RSpec.describe Memorb::IntegratorClassMethods do
  let(:integrator) { Class.new(Counter) { extend Memorb } }
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
    def class_method_overrides(integrator)
      Module.new.tap { |m| m.define_method(:memorb) { integrator } }
    end

    it 'calls override_if_possible on the integration' do
      expected_message = :override_if_possible
      method_name = :some_method
      integration = double('integration', expected_message => nil)
      integrator.singleton_class.prepend(class_method_overrides(integration))
      expect(integration).to receive(expected_message).with(method_name)
      integrator.define_method(method_name) { nil }
    end
  end
end
