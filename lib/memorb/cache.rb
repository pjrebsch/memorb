# frozen_string_literal: true

module Memorb
  class Cache

    def initialize
      @store = KeyValueStore.new
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

    def inspect
      rgx = Regexp.new(Regexp.escape(self.class.name) + ':0x\h+')
      original = super
      match = original.match(rgx)
      match ? "#<#{ match }>" : original
    end

  end
end
