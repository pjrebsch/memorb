module Memorb
  module Mixin
    module MixinClassMethods

      def prepended(base)
        @base = base
      end

      def name
        [:name, :inspect, :object_id].each do |m|
          base_name = @base.respond_to?(m) && @base.public_send(m)
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

    end
  end
end
