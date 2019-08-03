RSpec.describe Memorb::Configurable do
  describe '::new' do
    it 'returns a new instance with the given arguments' do
      args = [:one, :two, :three]
      result = described_class.new(*args)
      expect(result).to be_an_instance_of(described_class)
      instance_args = result.instance_variable_get(:@args)
      expect(instance_args).to eq(args)
    end
  end
  context 'when extended in a class' do
    it 'does not add its own methods to that class' do
      instance = described_class.new
      these_methods = Class.new { extend instance }.methods
      typical_methods = Class.new { extend Memorb }.methods
      expect(these_methods).to match_array(typical_methods)
    end
  end
end
