module Memorb
  module Mixin
    class << self

      @@mixins = KeyValueStore.new

      def mixin!(integrator)
        @@mixins.fetch(integrator) do
          new(integrator).tap do |mixin|
            integrator.extend IntegratorClassMethods
            integrator.prepend mixin
          end
        end
      end

      def for(integrator)
        @@mixins.read(integrator)
      end

      private

      def new(integrator)
        mixin = Module.new do
          extend MixinClassMethods

          def initialize(*)
            @memorb_cache = Memorb::Cache.new(integrator: self.class)
            super
          end

          def memorb
            @memorb_cache
          end
        end

        mixin.singleton_class.define_method(:integrator) { integrator }

        mixin
      end

    end
  end
end
