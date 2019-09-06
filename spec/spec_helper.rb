# frozen_string_literal: true

require_relative '../lib/memorb'

seed = RSpec.configuration.seed || Random.new_seed
puts "Seed used for tests: #{ seed }"
srand(seed)

class Counter

  def initialize
    @counter = 123
  end

  attr_reader :counter

  def increment
    @counter += 1
  end

  def double
    @counter *= 2
  end

end
