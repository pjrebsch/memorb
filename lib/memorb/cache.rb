module Memorb
  class Cache

    def initialize(store: Store.new)
      @store = store
    end

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

  end
end
