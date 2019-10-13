# frozen_string_literal: true

module Memorb
  # When Memorb code needs to be changed to accomodate older Ruby versions,
  # that code should live here. This has a few advantages:
  #   - it will be clear that there was a need to change the code for Ruby
  #     compatibility reasons
  #   - when the Ruby versions that required the altered code will no longer
  #     be supported, locating the places to refactor is easy
  #   - the specific approach needed to accommodate older version of Ruby
  #     and any explanatory comments need only be defined in one place
  module RubyCompatibility
    class << self

      # MRI < 2.5
      # These methods are `private` and require the use of `send`.
      %i[ define_method remove_method undef_method ].each do |m|
        eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
          def #{ m }(receiver, *args, &block)
            receiver.send(__method__, *args, &block)
          end
        RUBY
      end

      # JRuby *
      # JRuby doesn't work well with module singleton constants, so an
      # instance variable is used instead.
      def module_constant(receiver, key)
        receiver.instance_variable_get(ivar_name(key))
      end
      def module_constant_set(receiver, key, value)
        n = ivar_name(key)
        if receiver.instance_variable_defined?(n)
          raise "Memorb internal error! Reassignment of constant at #{ n }"
        end
        receiver.instance_variable_set(n, value)
      end

      # JRuby *
      # JRuby does not yet support `receiver` on `NameError`.
      # https://github.com/jruby/jruby/issues/5576
      def name_error_matches(error, expected_name, expected_receiver)
        return false unless error.name.equal?(expected_name)
        ::RUBY_ENGINE == 'jruby' || error.receiver.equal?(expected_receiver)
      end

      private

      def ivar_name(key)
        :"@#{ key }"
      end

    end
  end
end
