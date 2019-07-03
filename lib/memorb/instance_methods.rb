module Memorb
  module InstanceMethods

    def initialize(*)
      memorb_reset!
      super
    end

    def memorb?
      true
    end

    def memorb_reset!
      @memorb_cache = Core.fresh_cache
      nil
    end

    def memorb_write(*key, value)
      @memorb_cache[key] = value
    end

    def memorb_read(*key)
      @memorb_cache[key]
    end

    def memorb_has?(*key)
      @memorb_cache.include?(key)
    end

    def memorb_fetch(*key, &fallback)
      memorb_has?(*key) ? memorb_read(*key) : memorb_write(*key, fallback.call)
    end

    def memorb_forget(*key)
      @memorb_cache.delete(key)
      nil
    end

  end
end
