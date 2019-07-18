module Memorb
  module Mixin
    class << self

      @@mixins = KeyValueStore.new

      def mixin!(base)
        @@mixins.fetch(base) do
          new(base).tap do |mixin|
            base.extend IntegrationClassMethods
            base.prepend mixin
          end
        end
      end

      def for(klass)
        @@mixins.read(klass)
      end

      private

      def new(integrating_class)
        mixin = Module.new do
          extend MixinClassMethods

          def initialize(*)
            @memorb_cache = Memorb::Cache.new(integration: self.class)
            super
          end

          def memorb
            @memorb_cache
          end
        end

        mixin.singleton_class.define_method(:integrating_class) do
          integrating_class
        end

        mixin
      end

    end
  end
end
