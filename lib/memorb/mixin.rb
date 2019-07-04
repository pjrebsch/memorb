module Memorb
  module Mixin
    class << self

      @@mixins = Store.new

      def mixin(base)
        @@mixins.fetch(base) { mixin! base }
      end

      def for(klass)
        @@mixins.read(klass)
      end

      private

      def mixin!(base)
        base.extend ClassMethods
        base.prepend new
      end

      def new
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

          def initialize(*)
            @memorb_cache = Memorb::Cache.new
            super
          end

          def memorb
            @memorb_cache
          end
        end
      end

    end
  end
end
