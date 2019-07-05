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

end

class SimpleIntegration < Counter
  include Memorb
end

class ChildIntegration < SimpleIntegration
end

class DuplicateIntegration < Counter
  include Memorb
  include Memorb
end

class EnumerativeWithBracketsIntegration < Counter
  include Memorb[:increment]
end

class EnumerativeWithParenthesesIntegration < Counter
  include Memorb(:increment)
end
