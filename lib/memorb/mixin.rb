module Memorb
  module Mixin
    class << self

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
