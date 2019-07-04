module Memorb
  module Core

    class << self
      def fresh_cache
        Hash.new
      end

      def inclusion_procedure(base)
        base.extend ClassMethods
        base.prepend Mixin.new
      end
    end

  end
end
