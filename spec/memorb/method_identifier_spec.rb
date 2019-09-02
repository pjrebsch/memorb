RSpec.describe Memorb::MethodIdentifier do
  describe '::normalize' do
    it 'returns a symbol of the given method name' do
      result = described_class.normalize('method_1')
      expect(result).to be(:method_1)
    end
  end
  describe '::normalize_local_variables!' do
    it 'updates the given local variables with normalized method names' do
      var_1, var_2 = 'method_1', 'method_2'
      described_class.normalize_local_variables!(binding, :var_1, :var_2)
      expect(var_1).to be(:method_1)
      expect(var_2).to be(:method_2)
    end
  end
end
