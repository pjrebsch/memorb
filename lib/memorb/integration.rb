# frozen_string_literal: true

require 'concurrent'

module Memorb
  module Integration
    class << self

      def integrate_with!(target)
        unless target.is_a?(::Class)
          raise InvalidIntegrationError, 'integration target must be a class'
        end
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
        mixin = ::Module.new do
          def initialize(*)
            agent = Integration[self.class].create_agent(self)
            define_singleton_method(:memorb) { agent }
            super
          end

          class << self

            def register(*names, &block)
              names_present = !names.empty?
              block_present = !block.nil?

              if names_present && block_present
                raise ::ArgumentError,
                  'register may not be called with both a method name and a block'
              elsif names_present
                names.flatten.each { |n| _register_from_name(_identifier(n)) }
              elsif block_present
                _register_from_block(&block)
              else
                raise ::ArgumentError,
                  'register must be called with either a method name or a block'
              end

              nil
            end

            def registered_methods
              _identifiers_to_symbols(_registrations.keys)
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

            def enabled_methods
              _identifiers_to_symbols(_overrides.keys)
            end

            def disabled_methods
              registered_methods - enabled_methods
            end

            def enabled?(name)
              _enabled?(_identifier(name))
            end

            def auto_register?
              _auto_registration.value > 0
            end

            def auto_register!(&block)
              raise ::ArgumentError, 'a block must be provided' if block.nil?
              _auto_registration.update { |v| [0, v].max + 1 }
              begin
                block.call
              ensure
                _auto_registration.update { |v| [0, v - 1].max }
              end
            end

            def prepended(target)
              _check_target!(target)
              super
            end

            def included(*)
              raise InvalidIntegrationError,
                'an integration must be applied with `prepend`, not `include`'
            end

            def name
              [:name, :inspect, :object_id].each do |m|
                next unless integrator.respond_to?(m)
                base_name = integrator.public_send(m)
                return "Memorb::Integration[#{ base_name }]" if base_name
              end
            end

            alias_method :inspect, :name

            def create_agent(integrator_instance)
              Agent.new(integrator_instance.object_id)
            end

            private

            def _check_target!(target)
              unless target.equal?(integrator)
                raise MismatchedTargetError
              end
            end

            def _identifier(name)
              MethodIdentifier.new(name)
            end

            def _identifiers_to_symbols(method_ids)
              method_ids.map(&:to_sym)
            end

            def _register_from_name(method_id)
              _registrations.write(method_id, nil)
              _enable(method_id)
            end

            def _register_from_block(&block)
              auto_register! do
                integrator.class_eval(&block)
              end
            end

            def _registered?(method_id)
              _registrations.keys.include?(method_id)
            end

            def _enable(method_id)
              return unless _registered?(method_id)

              visibility = _integrator_instance_method_visibility(method_id)
              return if visibility.nil?

              _overrides.fetch(method_id) do
                _define_override(method_id)
                _set_visibility(visibility, method_id.to_sym)
              end
            end

            def _disable(method_id)
              _overrides.forget(method_id)
              _remove_override(method_id)
            end

            def _enabled?(method_id)
              _overrides.keys.include?(method_id)
            end

            def _remove_override(method_id)
              # Ruby will raise an exception if the method doesn't exist.
              # Catching it is the safest thing to do for thread-safety.
              # The alternative would be to check the list if it were
              # present or not, but the read could be outdated by the time
              # that we tried to remove the method and this exception
              # wouldn't be caught.
              remove_method(method_id.to_sym)
            rescue ::NameError => e
              # If this exception was for something else, it should be re-raised.
              unless RubyCompatibility.name_error_matches(e, method_id, self)
                raise e
              end
            end

            def _define_override(method_id)
              define_method(method_id.to_sym) do |*args, &block|
                memorb.method_store
                  .fetch(method_id) { KeyValueStore.new }
                  .fetch(args.hash) { super(*args, &block) }
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

            def _registrations
              RubyCompatibility.module_constant(self, :registrations)
            end

            def _overrides
              RubyCompatibility.module_constant(self, :overrides)
            end

            def _auto_registration
              RubyCompatibility.module_constant(self, :auto_registration)
            end

          end
        end

        RubyCompatibility.module_constant_set(mixin, :registrations, KeyValueStore.new)
        RubyCompatibility.module_constant_set(mixin, :overrides, KeyValueStore.new)
        RubyCompatibility.module_constant_set(mixin,
          :auto_registration,
          ::Concurrent::AtomicFixnum.new,
        )

        RubyCompatibility.define_method(mixin.singleton_class, :integrator) do
          integrator
        end

        mixin
      end

    end
  end
end
