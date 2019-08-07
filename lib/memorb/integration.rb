module Memorb
  module Integration
    class << self

      def integrate_with!(target)
        INTEGRATIONS.fetch(target) do
          new(target).tap do |integration|
            target.singleton_class.prepend(IntegratorClassMethods)
            target.prepend(integration)
          end
        end
      end

      def [](integrator)
        INTEGRATIONS.read(integrator)
      end

      private

      INTEGRATIONS = KeyValueStore.new

      def new(integrator)
        mixin = Module.new do
          def initialize(*)
            @memorb_cache = Memorb::Cache.new
            super
          end

          def memorb
            @memorb_cache
          end

          class << self

            REGISTRATIONS = KeyValueStore.new

            def prepended(base)
              check! base
            end

            alias_method :included, :prepended

            def name
              [:name, :inspect, :object_id].each do |m|
                next unless integrator.respond_to?(m)
                base_name = integrator.public_send(m)
                return "Memorb:#{ base_name }" if base_name
              end
            end

            alias_method :inspect, :name

            def register(name)
              REGISTRATIONS.write(name, nil)

              define_method(name) do |*args, &block|
                memorb.fetch(:"#{ name }", *args, block) do
                  super(*args, &block)
                end
              end
            end

            def unregister(name)
              REGISTRATIONS.forget(name)

              begin
                remove_method(name)
              rescue NameError
                # If attempting to unregister a method that isn't currently
                # registered, Ruby will raise an exception. Catching the
                # exception is the safest thing to do for thread-safety.
                # The alternative would be to check the register if it were
                # added or not, but the read could be outdated by the time
                # that we tried to remove the method and this exception
                # wouldn't be caught.
              end
            end

            def registered_methods
              REGISTRATIONS.keys
            end

            def registered?(name)
              registered_methods.include?(name)
            end

            private

            def check!(base)
              unless base.equal?(integrator)
                raise InvalidIntegrationError
              end
            end

          end
        end

        mixin.singleton_class.define_method(:integrator) { integrator }

        mixin
      end

    end
  end
end
