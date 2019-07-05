RSpec.describe Memorb::Configurable do
  let(:klass) { Memorb::Configurable }

  describe '::[]' do
    it 'returns a new Configurable with the given arguments' do
      args = [:one, :two, :three]
      result = klass[*args]
      expect(result).to be_an_instance_of(klass)
      instance_args = result.instance_variable_get(:@args)
      expect(instance_args).to eq(args)
    end
  end
end
