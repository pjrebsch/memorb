RSpec.shared_examples 'an integration' do |klass|
  describe '::memorb' do
    it 'returns the mixin for the class' do
      result = klass.memorb
      mixin = Memorb::Mixin.for(klass)
      expect(result).to equal(mixin)
    end
  end
  describe '#initialize' do
    it 'retains its original behavior' do
      instance = klass.new
      expect(instance.counter).to eq(123)
    end
    it 'initializes the memorb cache' do
      instance = klass.new
      cache = instance.memorb
      expect(cache).to be_an_instance_of(Memorb::Cache)
    end
  end
  describe 'memorb cache' do
    it 'is not shared across instances' do
      cache1 = klass.new.memorb
      cache2 = klass.new.memorb
      expect(cache1).not_to equal(cache2)
    end
  end
  describe 'ancestors' do
    it '...' do
      puts klass.ancestors.inspect
    end
  end
end

RSpec.shared_examples 'a registered integration' do |klass|
  it 'registers #increment' do
    mixin = Memorb::Mixin.for(klass)
    expect(mixin.public_instance_methods).to include(:increment)
  end
  it 'registers #double' do
    mixin = Memorb::Mixin.for(klass)
    expect(mixin.public_instance_methods).to include(:double)
  end
end

RSpec.shared_examples 'a duplicate integration' do |klass|
  describe 'ancestors' do
    it 'includes its memorb integration once' do
      ancestors = klass.ancestors
      valid = "Memorb:#{ klass.name }"
      mixins = ancestors.map(&:inspect).select { |a| a == valid }
      expect(mixins).to match_array([valid])
    end
  end
end

RSpec.describe BasicIntegration do
  it_behaves_like 'an integration', BasicIntegration
end

RSpec.describe ChildIntegration do
  it_behaves_like 'an integration', ChildIntegration
end

RSpec.describe DuplicateIntegration do
  klass = DuplicateIntegration
  it_behaves_like 'an integration', klass
  it_behaves_like 'a duplicate integration', klass
end

RSpec.describe ChildDuplicateIntegration do
  klass = ChildDuplicateIntegration
  it_behaves_like 'an integration', klass
  it_behaves_like 'a duplicate integration', klass
end

RSpec.describe EnumerativeWithBracketsIntegration do
  klass = EnumerativeWithBracketsIntegration
  it_behaves_like 'an integration', klass
  it_behaves_like 'a registered integration', klass
end

RSpec.describe EnumerativeWithParenthesesIntegration do
  klass = EnumerativeWithParenthesesIntegration
  it_behaves_like 'an integration', klass
  it_behaves_like 'a registered integration', klass
end

RSpec.describe PrependedBasicIntegration do
  it_behaves_like 'an integration', PrependedBasicIntegration
end

RSpec.describe PrependedEnumerativeIntegration do
  klass = PrependedEnumerativeIntegration
  it_behaves_like 'an integration', klass
  it_behaves_like 'a registered integration', klass
end
