RSpec.shared_examples 'an integrator' do
  let(:integrator) { described_class }
  let(:instance) { integrator.new }

  describe '#initialize' do
    it 'retains its original behavior' do
      expect(instance.counter).to eq(123)
    end
  end
  describe '#memorb' do
    it 'returns the memorb cache' do
      cache = instance.memorb
      expect(cache).to be_an_instance_of(Memorb::Cache)
    end
    it 'is not shared across instances' do
      cache1 = integrator.new.memorb
      cache2 = integrator.new.memorb
      expect(cache1).not_to equal(cache2)
    end
  end
end

RSpec.shared_examples 'a registered integrator' do
  let(:integrator) { described_class }

  it 'registers #increment' do
    mixin = Memorb::Mixin.for(integrator)
    expect(mixin.public_instance_methods).to include(:increment)
  end
  it 'registers #double' do
    mixin = Memorb::Mixin.for(integrator)
    expect(mixin.public_instance_methods).to include(:double)
  end
end

RSpec.describe BasicIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe ChildIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe DuplicateIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe ChildDuplicateIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe EnumerativeWithBracketsIntegrator do
  it_behaves_like 'an integrator'
  it_behaves_like 'a registered integrator'
end

RSpec.describe EnumerativeWithParenthesesIntegrator do
  it_behaves_like 'an integrator'
  it_behaves_like 'a registered integrator'
end

RSpec.describe PrependedBasicIntegrator do
  it_behaves_like 'an integrator'
end

RSpec.describe PrependedEnumerativeIntegrator do
  it_behaves_like 'an integrator'
  it_behaves_like 'a registered integrator'
end
