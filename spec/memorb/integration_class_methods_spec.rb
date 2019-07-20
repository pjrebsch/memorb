RSpec.describe Memorb::IntegrationClassMethods do
  let(:integration) { Class.new(Counter) { include Memorb } }

  describe '::inherited' do
    it 'makes children of integrations get their own mixin' do
      child_integration = Class.new(integration)
      mixin = Memorb::Mixin.for(child_integration)
      expect(mixin).not_to be(nil)
      expected_ancestry = [mixin, child_integration]
      expect(child_integration.ancestors).to start_with(*expected_ancestry)
    end
  end
  describe '::memorb' do
    it 'returns the mixin for the integration' do
      mixin = Memorb::Mixin.for(integration)
      expect(integration.memorb).to be(mixin)
    end
  end
end
