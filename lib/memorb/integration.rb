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
            agent = Integration[self.class].create_agent(self)
            define_singleton_method(:memorb) { agent }
            super
          end

          class << self

            REGISTRATIONS = KeyValueStore.new
            private_constant :REGISTRATIONS

            OVERRIDES = KeyValueStore.new
            private_constant :OVERRIDES

            AGENTS = KeyValueStore.new
            private_constant :AGENTS

            def register(name = nil, &block)
              name_present = !name.nil?
              block_present = !block.nil?

              if name_present && block_present
                raise ::ArgumentError,
                  'register may not be called with both a method name and a block'
              elsif name_present
                _register_from_name(_identifier(name))
              elsif block_present
                _register_from_block(&block)
              else
                raise ::ArgumentError,
                  'register must be called with either a method name or a block'
              end
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

            def purge(name)
              _purge(_identifier(name))
            end

            def auto_register?; @auto_register; end
            def auto_register=(bool)
              case bool
              when true, false
                @auto_register = bool
              else
                raise ::ArgumentError, 'Only boolean values are allowed'
              end
            end

            def prepended(base); _check_integrator!(base); end
            def included(base);  _check_integrator!(base); end

            def name
              [:name, :inspect, :object_id].each do |m|
                next unless integrator.respond_to?(m)
                base_name = integrator.public_send(m)
                return "Memorb:#{ base_name }" if base_name
              end
            end

            alias_method :inspect, :name

            # Never save reference to the integrator instance or it may
            # never be garbage collected!
            def create_agent(integrator_instance)
              Agent.new(integrator_instance.object_id).tap do |agent|
                AGENTS.write(agent.id, agent)

                # The proc must not be made here because it would save a
                # reference to `integrator_instance`.
                finalizer = _agent_finalizer(agent.id)
                ::ObjectSpace.define_finalizer(integrator_instance, finalizer)
              end
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

            def _register_from_name(method_id)
              REGISTRATIONS.write(method_id, nil)
              _enable(method_id)
            end

            def _register_from_block(&block)
              self.auto_register = true
              integrator.class_eval(&block)
              self.auto_register = false
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

            def _purge(method_id)
              AGENTS.keys.each do |id|
                agent = AGENTS.read(id)
                store = agent&.method_store&.read(method_id)
                store&.reset!
              end
            end

            def _remove_override(method_id)
              send(:remove_method, method_id.to_sym)
            rescue ::NameError
              # Ruby will raise an exception if the method doesn't exist.
              # Catching it is the safest thing to do for thread-safety.
              # The alternative would be to check the list if it were
              # present or not, but the read could be outdated by the time
              # that we tried to remove the method and this exception
              # wouldn't be caught.
            end

            def _define_override(method_id)
              send(:define_method, method_id.to_sym) do |*args, &block|
                memorb.method_store
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

            def _agent_finalizer(agent_id)
              # This must not be a lambda proc, otherwise GC hangs!
              ::Proc.new { AGENTS.forget(agent_id) }
            end

          end
        end

        mixin.auto_register = false
        mixin.singleton_class.send(:define_method, :integrator) { integrator }

        mixin
      end

    end
  end
end
