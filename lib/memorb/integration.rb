module Memorb
  module Integration

    def self.new(integrator)
      mixin = Module.new do
        def initialize(*)
          @memorb_cache = Memorb::Cache.new(integrator: self.class)
          super
        end

        def memorb
          @memorb_cache
        end

        class << self

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
              # registered, Ruby will raise an exception. Catching the
              # exception is the safest thing to do for thread-safety.
              # The alternative would be to check the register if it were
              # added or not, but the read could be outdated by the time
              # that we tried to remove the method and this exception
              # wouldn't be caught.
            end
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
