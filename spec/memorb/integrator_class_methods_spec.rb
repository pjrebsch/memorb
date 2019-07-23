RSpec.describe Memorb::IntegratorClassMethods do
  let(:integrator) { Class.new(Counter) { include Memorb } }

  describe '::inherited' do
    it 'makes children of integrators get their own mixin' do
      child_integrator = Class.new(integrator)
      mixin = Memorb::Mixin.for(child_integrator)
      expect(mixin).not_to be(nil)
      expected_ancestry = [mixin, child_integrator]
      expect(child_integrator.ancestors).to start_with(*expected_ancestry)
    end
  end
  describe '::memorb' do
    it 'returns the mixin for the integrator' do
      mixin = Memorb::Mixin.for(integrator)
      expect(integrator.memorb).to be(mixin)
    end
  end
end
