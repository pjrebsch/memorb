RSpec.describe Memorb::IntegratorClassMethods do
  let(:integrator) { Class.new(Counter) { include Memorb } }

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
      integration = Memorb::Integration[integrator]
      expect(integrator.memorb).to be(integration)
    end
  end
end
