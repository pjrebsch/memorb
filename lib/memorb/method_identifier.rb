module Memorb
  class MethodIdentifier

    class << self

      def normalize(name)
        name.to_s.to_sym
      end

      def normalize_local_variables!(context, *variable_names)
        variable_names.each do |n|
          m = context.local_variable_get(n)
          normalized = normalize(m)
          context.local_variable_set(n, normalized)
        end
      end

    end

  end
end
