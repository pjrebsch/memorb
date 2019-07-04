module Memorb
  module Core

    class << self
      def mixin(base)
        base.extend ClassMethods
        base.prepend Mixin.new
      end
    end

  end
end
