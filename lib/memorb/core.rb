require 'set'

module Memorb
  module Core

    IGNORED_INSTANCE_METHODS = Set[:initialize, :new].freeze

    class << self

      def fresh_cache
        Hash.new
      end

    end

  end
end
