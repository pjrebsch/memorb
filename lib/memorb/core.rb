require 'set'

module Memorb
  module Core

    IGNORED_INSTANCE_METHODS = Set[:initialize, :new].freeze

    class << self

      def fresh_cache
        Hash.new
      end

      def generate_mixin(methods)
        Module.new do
          def self.included(base)
            base.extend(ClassMethods)
            base.send(:prepend, InstanceMethods)
          end
        end
      end

    end

  end
end
