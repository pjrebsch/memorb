RSpec.shared_examples 'an integrator' do |klass|
  describe '#initialize' do
    it 'retains its original behavior' do
      instance = klass.new
      expect(instance.counter).to eq(123)
    end
  end
  describe '#memorb' do
    it 'returns the memorb cache' do
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
end

RSpec.shared_examples 'a registered integrator' do |klass|
  it 'registers #increment' do
    mixin = Memorb::Mixin.for(klass)
    expect(mixin.public_instance_methods).to include(:increment)
  end
  it 'registers #double' do
    mixin = Memorb::Mixin.for(klass)
    expect(mixin.public_instance_methods).to include(:double)
  end
end

RSpec.describe BasicIntegrator do
  it_behaves_like 'an integrator', BasicIntegrator
end

RSpec.describe ChildIntegrator do
  it_behaves_like 'an integrator', ChildIntegrator
end

RSpec.describe DuplicateIntegrator do
  klass = DuplicateIntegrator
  it_behaves_like 'an integrator', klass
end

RSpec.describe ChildDuplicateIntegrator do
  klass = ChildDuplicateIntegrator
  it_behaves_like 'an integrator', klass
end

RSpec.describe EnumerativeWithBracketsIntegrator do
  klass = EnumerativeWithBracketsIntegrator
  it_behaves_like 'an integrator', klass
  it_behaves_like 'a registered integrator', klass
end

RSpec.describe EnumerativeWithParenthesesIntegrator do
  klass = EnumerativeWithParenthesesIntegrator
  it_behaves_like 'an integrator', klass
  it_behaves_like 'a registered integrator', klass
end

RSpec.describe PrependedBasicIntegrator do
  it_behaves_like 'an integrator', PrependedBasicIntegrator
end

RSpec.describe PrependedEnumerativeIntegrator do
  klass = PrependedEnumerativeIntegrator
  it_behaves_like 'an integrator', klass
  it_behaves_like 'a registered integrator', klass
end
