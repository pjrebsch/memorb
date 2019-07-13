module Memorb
  module Mixin
    module MixinClassMethods

      def prepended(base)
        @base_name = base.name || base.inspect
      end

      def name
        "Memorb:#{ @base_name }"
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

    end
  end
end
