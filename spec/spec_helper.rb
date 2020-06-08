# frozen_string_literal: true

require_relative '../lib/memorb'

module SpecHelper
  class << self

    def basic_target_class
      ::Class.new do
        attr_reader :counter
        def initialize;  @counter = 0;  end
        def increment;   @counter += 1; end
        def double;      @counter *= 2; end
        def noop(*args); nil;           end
      end
    end

    def prng
      ::Random.new(::RSpec.configuration.seed)
    end

    def force_garbage_collection(wait_cycle: 0.05, min_passes: 1, max_passes: 2)
      ::GC.stress = true
      starting_count = ::GC.count
      min_count = starting_count + min_passes
      pass_count = 0

      ::GC.start
      current_count = ::GC.count

      # Wait for a garbage collection to occur.
      while current_count < min_count
        sleep wait_cycle
        current_count = ::GC.count
        pass_count += 1
        if pass_count >= max_passes
          raise "Exceeded maximum passes (#{max_passes}) for garbage collection during test"
        end
      end

      ::GC.stress = false
    end

    def test_method_name(stringlike, &block)
      ctx = block.binding.receiver
      [stringlike, stringlike.to_s].each do |converted|
        type = converted.class.name.downcase
        ctx.context "with method name supplied as a #{ type }" do
          instance_exec(stringlike, converted, &block)
        end
      end
    end

    def for_testing_garbage_collection(&block)
      # JRuby garbage collection isn't as straightforward as CRuby, so tests
      # that rely on garbage collection are skipped. The expectation is that
      # if this works for CRuby's GC, then it should work for the GCs of other
      # Ruby implementations.
      if ::RUBY_ENGINE != 'jruby'
        # RSpec blocks aren't allowing out-of-scope variables to be garbage
        # collected, so `WeakRef` is used to work around that.
        require 'weakref'

        block.call
      end
    end

  end
end
