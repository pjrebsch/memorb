# frozen_string_literal: true

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
            cache = Memorb::Cache.new(object_id)
            integration = Integration[self.class]
            registry = integration.singleton_class.const_get(:CACHES)
            finalizer = integration.cache_finalizer(cache.id)

            @memorb_cache = registry.write(cache.id, cache)
            define_singleton_method(:memorb) { @memorb_cache }

            ObjectSpace.define_finalizer(self, finalizer)

            super
          end

          class << self

            REGISTRATIONS = KeyValueStore.new
            private_constant :REGISTRATIONS

            OVERRIDES = KeyValueStore.new
            private_constant :OVERRIDES

            CACHES = KeyValueStore.new
            private_constant :CACHES

            def prepended(base); _check_integrator!(base); end
            def included(base); _check_integrator!(base); end

            def name
              [:name, :inspect, :object_id].each do |m|
                next unless integrator.respond_to?(m)
                base_name = integrator.public_send(m)
                return "Memorb:#{ base_name }" if base_name
              end
            end

            alias_method :inspect, :name

            def cache_finalizer(cache_key)
              proc { CACHES.forget(cache_key) }
            end

            def register(name)
              _register(_identifier(name))
            end

            def registered_methods
              _identifiers_to_symbols(REGISTRATIONS.keys)
            end

            def registered?(name)
              _registered?(_identifier(name))
            end

            def enable(name)
              _enable(_identifier(name))
            end

            def disable(name)
              _disable(_identifier(name))
            end

            def overridden_methods
              _identifiers_to_symbols(OVERRIDES.keys)
            end

            def overridden?(name)
              _overridden?(_identifier(name))
            end

            private

            def _check_integrator!(base)
              unless base.equal?(integrator)
                raise InvalidIntegrationError
              end
            end

            def _identifier(name)
              MethodIdentifier.new(name)
            end

            def _identifiers_to_symbols(method_ids)
              method_ids.map(&:to_sym)
            end

            def _register(method_id)
              REGISTRATIONS.write(method_id, nil)
              _enable(method_id)
            end

            def _registered?(method_id)
              REGISTRATIONS.keys.include?(method_id)
            end

            def _enable(method_id)
              return unless _registered?(method_id)

              visibility = _integrator_instance_method_visibility(method_id)
              return if visibility.nil?

              OVERRIDES.fetch(method_id) do
                _define_override(method_id)
                _set_visibility(visibility, method_id.to_sym)
              end
            end

            def _disable(method_id)
              OVERRIDES.forget(method_id)
              _remove_override(method_id)
            end

            def _overridden?(method_id)
              OVERRIDES.keys.include?(method_id)
            end

            def _remove_override(method_id)
              remove_method(method_id.to_sym)
            rescue NameError
              # Ruby will raise an exception if the method doesn't exist.
              # Catching it is the safest thing to do for thread-safety.
              # The alternative would be to check the list if it were
              # present or not, but the read could be outdated by the time
              # that we tried to remove the method and this exception
              # wouldn't be caught.
            end

            def _define_override(method_id)
              define_method(method_id.to_sym) do |*args, &block|
                memorb
                  .fetch(method_id) { KeyValueStore.new }
                  .fetch([*args, block]) { super(*args, &block) }
              end
            end

            def _integrator_instance_method_visibility(method_id)
              [:public, :protected, :private].find do |visibility|
                methods = integrator.send(:"#{ visibility }_instance_methods")
                methods.include?(method_id.to_sym)
              end
            end

            def _set_visibility(visibility, name)
              send(visibility, name)
              visibility
            end

          end
        end

        mixin.singleton_class.define_method(:integrator) { integrator }

        mixin
      end

    end
  end
end
