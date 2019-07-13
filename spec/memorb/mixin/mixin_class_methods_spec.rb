RSpec.describe Memorb::Mixin::MixinClassMethods do
  let(:mixin) { Memorb::Mixin.for(integration) }
  let(:integration) {
    Class.new(Counter) { include Memorb }
  }

  describe '#register' do
    it 'caches the registered method' do
      mixin.register(:increment)
      instance = integration.new
      result1 = instance.increment
      result2 = instance.increment
      expect(result1).to eq(result2)
    end
    context 'when registering a method multiple times' do
      it 'still caches the registered method' do
        mixin.register(:increment)
        mixin.register(:increment)
        instance = integration.new
        result1 = instance.increment
        result2 = instance.increment
        expect(result1).to eq(result2)
      end
    end
    context 'when registering a method that does not exist' do
      it 'still allows the method to be registered' do
        expect { mixin.register(:undefined_method) }.not_to raise_error
      end
      it 'responds to the method' do
        mixin.register(:undefined_method)
        instance = integration.new
        expect(instance).to respond_to(:undefined_method)
      end
      it 'raises an error when trying to call it' do
        mixin.register(:undefined_method)
        instance = integration.new
        expect { instance.undefined_method }.to raise_error(NoMethodError)
      end
    end
  end
  describe '#unregister' do
    it 'removes the override method for the given method' do
      mixin.register(:increment)
      mixin.unregister(:increment)
      expect(mixin.public_instance_methods).not_to include(:increment)
    end
    context 'when there is no override method defined' do
      it 'does not raise an error' do
        expect { mixin.unregister(:undefined_method!) }.not_to raise_error
      end
    end
    context 'when a method is registered multiple times' do
      it 'still unregisters the method' do
        mixin.register(:increment)
        mixin.register(:increment)
        mixin.unregister(:increment)
        expect(mixin.public_instance_methods).not_to include(:increment)
      end
    end
  end
end
