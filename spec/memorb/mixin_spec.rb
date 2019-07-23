RSpec.describe Memorb::Mixin do
  let(:klass) { Class.new }

  describe 'class methods of Mixin' do
    subject { Memorb::Mixin }

    describe '::mixin!' do
      it 'returns the mixin for the given class' do
        result = subject.mixin! klass
        expect(result).not_to be(nil)
      end
      context 'when called more than once for a given class' do
        it 'returns the same mixin every time' do
          result1 = subject.mixin! klass
          result2 = subject.mixin! klass
          expect(result1).to be(result2)
        end
        it 'includes the mixin with the integrating class only once' do
          mixin = subject.mixin!(klass); subject.mixin!(klass)
          ancestors = klass.ancestors
          mixins = ancestors.select { |a| a.equal? mixin }
          expect(mixins).to match_array([mixin])
        end
      end
    end
    describe '::for' do
      it 'returns the mixin for the given class' do
        mixin = subject.mixin! klass
        result = subject.for(klass)
        expect(result).to be(mixin)
      end
      context 'when given a class that has not been called with mixin!' do
        it 'returns nil' do
          result = subject.for(klass)
          expect(result).to be(nil)
        end
      end
    end
  end
  describe 'class methods of an instance of Mixin' do
    subject { Memorb::Mixin.mixin! klass }

    describe '::integrator' do
      it 'returns its integrating class' do
        expect(subject.integrator).to be(klass)
      end
    end
  end
  context 'when mixing in with another class' do
    let(:error) { Memorb::InvalidMixinError }

    it 'raises an error when using prepend' do
      mixin = subject.mixin! klass
      expect { Class.new { prepend mixin } }.to raise_error(error)
    end
    it 'raises an error when using include' do
      mixin = subject.mixin! klass
      expect { Class.new { include mixin } }.to raise_error(error)
    end
  end
end
