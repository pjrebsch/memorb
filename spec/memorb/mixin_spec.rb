RSpec.describe Memorb::Mixin do
  subject { Memorb::Mixin }
  let(:klass) { Class.new }

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
