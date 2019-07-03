RSpec.describe ImplementationChild do
  it 'does not respond to #memorb?' do
    impc = ImplementationChild.new
    expect(impc).to respond_to(:memorb?)
  end
  describe 'memorb cache' do
    it 'is not shared across parent and child instances' do
      cache1 = Implementation.new.instance_variable_get(:@memorb_cache)
      cache2 = ImplementationChild.new.instance_variable_get(:@memorb_cache)
      expect(cache1).not_to equal(cache2)
    end
  end
end
