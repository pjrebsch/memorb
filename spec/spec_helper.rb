# frozen_string_literal: true

require_relative '../lib/memorb'

seed = RSpec.configuration.seed || Random.new_seed
puts "Seed used for tests: #{ seed }"
srand(seed)

module SpecHelper
  class << self

    def basic_target_class
      Class.new do
        attr_reader :counter
        def initialize; @counter = 0;  end
        def increment;  @counter += 1; end
        def double;     @counter *= 2; end
      end
    end

  end
end
