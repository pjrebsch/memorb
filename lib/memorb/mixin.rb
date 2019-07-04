module Memorb
  module Mixin

    def self.new
      Module.new do
        def self.prepended(base)
          @base_name = base.name
        end

        def self.name
          "Memorb(#{ @base_name })"
        end

        def self.inspect
          name
        end

        def self.address
          (object_id << 1).to_s(16)
        end

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

  end
end
