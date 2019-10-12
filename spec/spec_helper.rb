# frozen_string_literal: true

require_relative '../lib/memorb'

module SpecHelper
  class << self

    def basic_target_class
      ::Class.new do
        attr_reader :counter
        def initialize; @counter = 0;  end
        def increment;  @counter += 1; end
        def double;     @counter *= 2; end
      end
    end

    def rng
      ::Random.new(::RSpec.configuration.seed)
    end

    def force_garbage_collection(wait_cycle: 0, min_passes: 1)
      ::GC.stress = true
      ::GC.start

      # Wait for a garbage collection to occur.
      a = b = ::GC.count
      while b < a + min_passes
        sleep wait_cycle
        b = ::GC.count
      end

      ::GC.stress = false
    end

  end
end
