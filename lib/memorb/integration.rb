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
              _register(_identifier(name))
            end

            def registered_methods
              REGISTRATIONS.keys.map(&:to_sym)
            end

            def registered?(name)
              _registered?(_identifier(name))
            end

            def enable(name)
              _override_if_possible(_identifier(name))
            end

            def disable(name)
              _disable(_identifier(name))
            end

            def overridden_methods
              OVERRIDES.keys.map(&:to_sym)
            end

            def overridden?(name)
              method_id = MethodIdentifier.new(name)
              OVERRIDES.keys.include?(method_id)
            end

            def set_visibility!(visibility, *names)
              return unless [:public, :protected, :private].include?(visibility)
              send(visibility, *names)
              visibility
            end

            private

            def check!(base)
              unless base.equal?(integrator)
                raise InvalidIntegrationError
              end
            end

            def _identifier(name)
              MethodIdentifier.new(name)
            end

            def _register(method_id)
              REGISTRATIONS.write(method_id, nil)
              _override_if_possible(method_id)
            end

            def _registered?(method_id)
              REGISTRATIONS.keys.include?(method_id)
            end

            def _override_if_possible(method_id)
              return unless _registered?(method_id)

              visibility = integrator_instance_method_visibility(method_id)
              return if visibility.nil?

              override!(method_id, visibility)
            end

            def _disable(method_id)
              OVERRIDES.forget(method_id)
              remove_override!(method_id)
            end

            def override!(method_id, visibility)
              OVERRIDES.fetch(method_id) do
                define_override!(method_id)
                set_visibility!(visibility, method_id.to_sym)
              end
            end

            def remove_override!(method_id)
              remove_method(method_id.to_sym)
            rescue NameError
              # Ruby will raise an exception if the method doesn't exist.
              # Catching it is the safest thing to do for thread-safety.
              # The alternative would be to check the list if it were
              # present or not, but the read could be outdated by the time
              # that we tried to remove the method and this exception
              # wouldn't be caught.
            end

            def define_override!(method_id)
              define_method(method_id.to_sym) do |*args, &block|
                memorb.fetch(method_id, *args, block) do
                  super(*args, &block)
                end
              end
            end

            def integrator_instance_method_visibility(method_id)
              [:public, :protected, :private].find do |visibility|
                methods = integrator.send(:"#{ visibility }_instance_methods")
                methods.include?(method_id.to_sym)
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
