RSpec.describe Memorb::Mixin do
  let(:klass) { Class.new }

  describe 'class methods of an instance of Mixin' do
    subject { Memorb.integrate!(klass) }

    describe '::integrator' do
      it 'returns its integrating class' do
        expect(subject.integrator).to be(klass)
      end
    end
  end
  context 'when mixing in with another class' do
    let(:error) { Memorb::InvalidMixinError }

    it 'raises an error when using prepend' do
      integration = Memorb.integrate!(klass)
      expect { Class.new { prepend integration } }.to raise_error(error)
    end
    it 'raises an error when using include' do
      integration = Memorb.integrate!(klass)
      expect { Class.new { include integration } }.to raise_error(error)
    end
  end
end
