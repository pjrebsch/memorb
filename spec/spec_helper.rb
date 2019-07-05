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

class BasicIntegration < Counter
  include Memorb
end

class ChildIntegration < BasicIntegration
end

class DuplicateIntegration < Counter
  include Memorb
  include Memorb
end

class ChildDuplicateIntegration < BasicIntegration
  include Memorb
end

class EnumerativeWithBracketsIntegration < Counter
  include Memorb[:increment, :double]
end

class EnumerativeWithParenthesesIntegration < Counter
  include Memorb(:increment, :double)
end

class PrependedBasicIntegration < Counter
  prepend Memorb
end

class PrependedEnumerativeIntegration < Counter
  prepend Memorb[:increment, :double]
end
