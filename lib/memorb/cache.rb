module Memorb
  class Cache

    def initialize(integration:, store: KeyValueStore.new)
      @integration = integration
      @mixin = Mixin.for(integration)
      @store = store
    end

    attr_reader :integration, :mixin

    def write(*key, value)
      @store.write(key, value)
    end

    def read(*key)
      @store.read(key)
    end

    def fetch(*key, &fallback)
      @store.fetch(key, &fallback)
    end

    def forget(*key)
      @store.forget(key)
    end

    def reset!
      @store.reset!
    end

    def register(method_name)
      mixin.register(method_name)
      nil
    end

    def unregister(method_name)
      mixin.unregister(method_name)
      nil
    end

    def inspect
      rgx = Regexp.new(self.class.name + ':0x\h+')
      original = super
      match = original.match(rgx)
      match ? "#<#{ match }>" : original
    end

  end
end
