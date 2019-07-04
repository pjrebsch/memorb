RSpec.shared_examples 'an implementation' do |klass|
  describe '#initialize' do
    it 'retains its original behavior' do
      imp = klass.new
      expect(imp.counter).to eq(123)
    end
    it 'initializes the memorb cache' do
      imp = klass.new
      cache = imp.instance_variable_get(:@memorb_cache)
      expect(cache).to eq(Hash.new)
    end
  end
  describe 'memorb cache' do
    it 'is not shared across instances' do
      cache1 = klass.new.instance_variable_get(:@memorb_cache)
      cache2 = klass.new.instance_variable_get(:@memorb_cache)
      expect(cache1).not_to equal(cache2)
    end
  end
  describe 'ancestors' do
    it '...' do
      puts klass.ancestors.inspect
    end
  end
end

RSpec.describe SimpleImplementation do
  it_behaves_like 'an implementation', SimpleImplementation
end

RSpec.describe EnumerativeImplementation do
  it_behaves_like 'an implementation', EnumerativeImplementation
end

RSpec.describe ChildImplementation do
  it_behaves_like 'an implementation', ChildImplementation
end
