# Memorb

Memoize instance methods more succinctly.

## What problem does this address?

Sometimes you want to execute an instance method and have its result cached for future calls. You may want to do this because:

- the method is expensive to execute and caching its result would increase application performance
- the method returns a newly instantiated object which shouldn't be recreated on subsequent calls
- you simply want to lazily load some data and have it cached for some period of time

Below is a contrived `Rectangle` class that will be used for demonstration. The `area` and `perimeter` methods represent computationally expensive methods that can't be calculated before instantiation, but whose results won't change for the lifetime of the instance and can therefore be cached.

```ruby
class Rectangle

  def initialize(width:, height:)
    @width = width
    @height = height
  end

  attr_reader :width, :height

  def area
    width * height
  end

  def perimeter
    2 * (width + height)
  end

  def square?
    width == height
  end

end
```

The common and succinct way of accomplishing this in most cases is to memoize the result in an instance variable:

```ruby
def square?
  @square ||= width == height
end
```

But this approach has a few problems:

- if the result is falesy, the cached value is bypassed and the computation re-executed on subsequent calls
- concurrent calls to the method could result in its repeated computation when that may not be desirable
- having many methods saved in instance variables could make inspection of the instance a harder to parse
- if the chosen variable name is long, it could cause line wrapping when that would otherwise not be necessary
- the instance variable name is often chosen to match the name of the method, but method name punctuation can make this impossible

The falsey result problem could be solved by checking if the instance variable is `defined?` instead:

```ruby
def square?
  defined?(@square) ? @square : @square = width == height
end
```

But this approach gets a bit repetitive with the instance variable and is harder to read.

There must be a better way...

## The Solution

Memorb solves all of these problems and more! Just specify which methods should be memoized:

```ruby
class Rectangle
  include Memorb[:area, :perimeter, :square?]
  # ...
end
```
