module Memorb
  # KeyValueStore is a key-value store that can be used as a thread-safe
  # alternative to a Hash, but uses a different, limited interface.
  #
  # Thread safety is important here because an implementing class may
  # be using Memorb and expecting that a cacheable method be executed
  # only once. When a cacheable method is called, Memorb calls #fetch
  # on this KeyValueStore and expects it to be an atomic operation.
  # Without thread safety, a TOCTOU bug exists with the #fetch method where
  # another thread could write to a given key in the cache after #fetch
  # has determined that the key doesn't exist yet, causing a double-write
  # to the cache (or possibly a double-execution of the original cacheable
  # method).
  #
  class KeyValueStore

    def initialize
      @data = {}
    end

    def write(key, value)
      @data[key] = value
    end

    def read(key)
      @data[key]
    end

    def has?(key)
      @data.include?(key)
    end

    def fetch(key, &fallback)
      has?(key) ? read(key) : write(key, fallback.call)
    end

    def forget(key)
      @data.delete(key)
      nil
    end

    def reset!
      @data.clear
    end

    def inspect
      "#<#{ self.class.name }(#{ @data.keys.map(&:inspect).join(', ') })>"
    end

  end
end
