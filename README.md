# Memorb

Memoize instance methods more succinctly.

## Overview

### Why memoize?

Sometimes you want to execute an instance method and have its result cached for future calls. You may want this because the method:

- is computationally expensive and caching its result would increase application performance
- should only be executed once (perhaps it returns a newly instantiated object which shouldn't be recreated on subsequent calls)
- makes calls to an external service which should be limited for performance, API rate limiting, etc.

### What's the problem?

Below is a simple, contrived class that will be used for demonstration.

```ruby
class WeekForecast

  def initialize(starting:)
    @date = starting
  end

  def payload
    API::Payload.get '/weather/week', { date: @date }
  end

  def rain_on?(week_day)
    percent_chance = payload.dig('days', week_day.to_s, 'rain')
    percent_chance > 75 if percent_chance
  end

  def week_days
    Date::ABBR_DAYNAMES.rotate(@date)
  end

  def will_rain?
    week_days.any? { |wd| rain_on? wd }
  end

end
```

A common way of accomplishing memoization in most cases is to memoize the result in an instance variable:

```ruby
def will_rain?
  @will_rain ||= ...
end
```

But this simplistic approach has a few problems:

- if the result is falsey, the cached value is bypassed and the computation re-executed on subsequent calls
- results from methods aren't distinguished by their arguments
- concurrent calls to the method could result in multiple executions when that may not be desirable
- having many methods saved in instance variables could make inspection of the instance a harder to read
- if the chosen variable name is long, it could cause line wrapping when that would otherwise be unnecessary
- the instance variable name is often chosen to match the name of the method, but method name punctuation can make this impossible

The falsey result problem could be solved by checking if the instance variable is `defined?` instead:

```ruby
def will_rain?
  defined?(@will_rain) ? @will_rain : @will_rain = ...
end
```

But this approach gets a bit repetitive with the instance variable, is harder to read, and doesn't resolve any of the other problems.

Memorb offers a way to solve all of these problems and more!

## How does it work?

Specifying methods to be memoized by Memorb is referred to as "registering" them. When a method is registered, Memorb will override it so that when it's first called its return value is cached to be returned immediately on every call thereafter. Internally, calls to the overridden method are serialized with a read-write lock implementation to guarantee that the initial call is not subject to a race condition between threads while optimizing the performance of concurrent reads of the cached result.

## Usage

At a minimum, you just need specify which methods should be cached and you're done! The following are supported ways to register methods:

### Inline Registration

This approach registers methods along with the inclusion of Memorb. It is still possible to register additional methods later. You may use parentheses instead of brackets if you wish—they are functionally equivalent.

```ruby
class WeekForecast
  extend Memorb[:payload, :week_days, :rain_on?, :will_rain?]
  ...
end
```

## Advisories

### Registering methods that aren't (yet) defined

Memorb will allow you to register a method to be memoized before that method is actually defined. In fact, this is the normal behavior when using inline registration. However, since registration of a method adds it to the prepended mixin for the class, `respond_to?` will return true on all instances, even if the method never actually gets defined on them.

**There are plans to change automatic method overriding upon registration which would resolve this.**
