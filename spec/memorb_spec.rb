RSpec.describe Memorb do
  subject { described_class }
  let(:klass) { Class.new }

  describe '::integrate!' do
    it 'returns the integration for the given class' do
      result = subject.integrate!(klass)
      expect(result).not_to be(nil)
    end
    context 'when called more than once for a given class' do
      it 'returns the same integration every time' do
        result1 = subject.integrate!(klass)
        result2 = subject.integrate!(klass)
        expect(result1).to be(result2)
      end
      it 'includes the integration with the integrator only once' do
        subject.integrate!(klass)
        integration = subject.integrate!(klass)
        ancestors = klass.ancestors
        integrations = ancestors.select { |a| a.equal? integration }
        expect(integrations).to match_array([integration])
      end
    end
  end
  describe '::integration' do
    it 'returns the integration for the given class' do
      integration = subject.integrate!(klass)
      result = subject.integration(klass)
      expect(result).to be(integration)
    end
    context 'when given a class that has not been called with integrate!' do
      it 'returns nil' do
        result = subject.integration(klass)
        expect(result).to be(nil)
      end
    end
  end
end
