module Memorb
  module Core

    class << self

      def fresh_cache
        Hash.new
      end

      def generate_mixin
        Module.new do
          include InstanceMethods

          def self.included(base)
            base.extend(ClassMethods)
            @base_name = base.name
          end

          def self.name
            "Memorb(#{ @base_name })"
          end

          def self.inspect
            name
          end

          def self.address
            (object_id << 1).to_s(16)
          end
        end
      end

    end

  end
end
