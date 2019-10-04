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

      # <2.5
      # these methods are `private` and require the use of `send`
      %i[ define_method remove_method undef_method ].each do |m|
        eval(<<~RUBY)
          def #{ m }(receiver, *args, &block)
            receiver.send(__method__, *args, &block)
          end
        RUBY
      end

    end
  end
end
