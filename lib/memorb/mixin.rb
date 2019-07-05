module Memorb
  module Mixin

    module IntegrationClassMethods
      def inherited(child)
        Mixin.mixin!(child)
      end
    end

    module MixinClassMethods
      def prepended(base)
        @base_name = base.name || base.inspect
      end

      def name
        "Memorb(#{ @base_name })"
      end

      alias_method :inspect, :name

      def register(name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{ name }(*args, &block)
            memorb.fetch(:"#{ name }", *args, block) do
              super
            end
          end
        RUBY
      end

      def unregister(name)
        begin
          remove_method(name)
        rescue NameError
          # If attempting to unregister a method that isn't currently
          # registered, Ruby will raise an exception. Simply catching
          # it here makes the process of registering and unregistering
          # thread-safe.
        end
      end
    end

    @@mixins = KeyValueStore.new

    class << self

      def mixin!(base)
        @@mixins.fetch(base) do
          new.tap do |mixin|
            base.extend IntegrationClassMethods
            base.prepend mixin
          end
        end
      end

      def for(klass)
        @@mixins.read(klass)
      end

      private

      def new
        Module.new do
          extend MixinClassMethods

          def initialize(*)
            @memorb_cache = Memorb::Cache.new(integration: self.class)
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
