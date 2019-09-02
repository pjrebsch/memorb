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

      def integrated?(target)
        INTEGRATIONS.has?(target)
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
            private_constant :REGISTRATIONS

            OVERRIDES = KeyValueStore.new
            private_constant :OVERRIDES

            def prepended(base); check!(base); end
            def included(base); check!(base); end

            def name
              [:name, :inspect, :object_id].each do |m|
                next unless integrator.respond_to?(m)
                base_name = integrator.public_send(m)
                return "Memorb:#{ base_name }" if base_name
              end
            end

            alias_method :inspect, :name

            def register(name)
              register!(name)
              override_if_possible(name)
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

            def override_if_possible(name)
              return unless registered?(name)

              visibility = integrator_instance_method_visibility(name)
              return if visibility.nil?

              override!(name, visibility)
            end

            def overridden_methods
              OVERRIDES.keys
            end

            def overridden?(name)
              overridden_methods.include?(name)
            end

            def set_visibility!(name, visibility)
              return unless [:public, :protected, :private].include?(visibility)
              send(visibility, name)
              visibility
            end

            private

            def check!(base)
              unless base.equal?(integrator)
                raise InvalidIntegrationError
              end
            end

            def register!(name)
              REGISTRATIONS.write(name, nil)
            end

            def override!(name, visibility)
              OVERRIDES.fetch(name) do
                name = :"#{ name }"
                define_override!(name)
                set_visibility!(name, visibility)
              end
            end

            def define_override!(name)
              define_method(name) do |*args, &block|
                memorb.fetch(name, *args, block) do
                  super(*args, &block)
                end
              end
            end

            def integrator_instance_method_visibility(name)
              [:public, :protected, :private].find do |visibility|
                methods = integrator.send(:"#{ visibility }_instance_methods")
                methods.include?(name)
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
