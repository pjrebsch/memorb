module Memorb
  class Cache

    def initialize(integration:)
      @integration = integration
      @mixin = Mixin.for(integration)
      @store = KeyValueStore.new
    end

    attr_reader :integration

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
      @mixin.register(method_name)
    end

    def unregister(method_name)
      @mixin.unregister(method_name)
    end

    def inspect
      rgx = Regexp.new(Regexp.escape(self.class.name) + ':0x\h+')
      original = super
      match = original.match(rgx)
      match ? "#<#{ match }>" : original
    end

  end
end
