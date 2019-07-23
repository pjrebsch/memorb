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

class BasicIntegrator < Counter
  include Memorb
end

class ChildIntegrator < BasicIntegrator
end

class DuplicateIntegrator < Counter
  include Memorb
  include Memorb
end

class ChildDuplicateIntegrator < BasicIntegrator
  include Memorb
end

class EnumerativeWithBracketsIntegrator < Counter
  include Memorb[:increment, :double]
end

class EnumerativeWithParenthesesIntegrator < Counter
  include Memorb(:increment, :double)
end

class PrependedBasicIntegrator < Counter
  prepend Memorb
end

class PrependedEnumerativeIntegrator < Counter
  prepend Memorb[:increment, :double]
end
