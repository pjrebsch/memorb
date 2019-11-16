# Memorb

Memoize instance methods with ease.

[![CircleCI](https://circleci.com/gh/pjrebsch/memorb/tree/master.svg?style=svg)](https://circleci.com/gh/pjrebsch/memorb/tree/master)

## Overview

This is a contrived example class that could benefit from memoization. It is designed for demonstration, not for making a good case for the use of memoization.

```ruby
class WeekForecast

  def initialize(date:)
    @date = date
  end

  def data
    API.get '/weather/week', { date: @date.iso8601 }
  end

  def week_days
    Date::ABBR_DAYNAMES.rotate(@date.wday)
  end

  def rain_on?(day)
    percent_chance = data.dig('days', day.to_s, 'rain')
    percent_chance > 75 if percent_chance
  end

  def will_rain?
    week_days.any? { |wd| rain_on? wd }
  end

end
```

All of its instance methods could be memoized to save them from unnecessary recomputation or I/O.

A common way of accomplishing memoization is to save the result in an instance variable:

```ruby
@will_rain ||= ...
```

But that approach is problematic for expressions that return a falsey value as the instance variable will be overlooked on subsequent evaluations. Often, the solution for this case is to instead check whether or not the instance variable has been previously defined:

```ruby
defined?(@will_rain) ? @will_rain : @will_rain = ...
```

While this does address the issue of falsey values, this is significantly more verbose. And neither of these approaches take into consideration the arguments to the method, which a method like `rain_on?` in the above example class would need to function properly.

Memorb exists to make memoization in these cases much easier to implement. Simply register the methods with Memorb on the class and you're done:

```ruby
class WeekForecast
  extend Memorb
  memorb.register :data, :week_days, :rain_on?, :will_rain?
  ...
end
```

These methods' return values will now be memoized on each instance of `WeekForecast`. The `rain_on?` method will memoize its return values based on the arguments supplied to it (in this case one argument since that's all it accepts), and the other methods will each memoize their single, independent return value.

There are a few other benefits to using Memorb than just ease of implementation. Using instance variables directly can make default inspection of the instance more difficult, and unfortunately timed concurrent initial invocations of a method could result in unexpected computations of what was expected to be computed once. Memorb assists with the former and prevents the latter.

## Usage

The first requirement is that a class must extend the `Memorb` module.

Instance methods can be registered from a class definition with the `memorb.register` or `memorb!` methods by passing in a list of method names as was seen in the example from the previous section.

Conveniently, methods defined using the `def` keyword return the method name, so the method definition can just be prefixed with a registration directive. This approach helps make apparent the fact that the method is being memoized when reading the method.

```ruby
class WeekForecast
  extend Memorb
  memorb! def week_days
    ...
  end
end
```

If you prefer `def` and `end` to align, you can move `memorb!` up to a new line and escape the line break. The Memorb registration methods require arguments, so if you forget the escape the line break, you'll be made aware when the class itself is loaded.

```ruby
memorb! \
def week_days
  ...
end
```

## How does it work?

Specifying methods to be memoized by Memorb is referred to as "registering" them. When a method is registered and defined, Memorb will override it so that on initial invocation, the method's return value is cached to be returned immediately on every invocation thereafter. Once the method has been overridden, it is considered "enabled" for Memorb functionality. Internally, calls to the overriding method implementation are serialized with a read-write lock to guarantee that the initial method call is not subject to a race condition between threads, while also optimizing the performance of concurrent reads of the cached result.

## Cache explosion

No, sorry, not [the show](https://www.cashexplosionshow.com/).

Because memoization trades memory for computation savings, there is potential for memory explosion with a method that accepts arguments. All distinct sets of arguments to a method will map to a return value, and this mapping will be stored, so the potential for explosion increases exponentially as more arguments are supported. As long as the method is guaranteed to be called with a small, finite set of arguments, this shouldn't be a concern. But if the method is expected to handle arbitrary arguments or a large range of values, you may want to handle caching at a lower level within the method or abandon the memoization/caching approach altogether.

The `rain_on?` method in the example class represents a method that is subject to this. It can also be used as a good example of how to handle caching at a lower level. The only valid arguments are a representation of the seven days of the week, so there need only ever be up to seven cache entries. The day might not always be passed as a string—it might be passed as a symbol. The logic of the method makes no distinction because it always transforms the argument to a string, but Memorb can't know that the method considers them to be the same thing, so it would cache them as distinct values. This kind of "argument normalization" is another reason for handling caching inside the method.

```ruby
def rain_on?(day)
  day = day.to_s
  return unless week_days.include?(day)
  memorb.fetch(:rain_on?, day) do
    percent_chance = data.dig('days', day, 'rain')
    percent_chance > 75 if percent_chance
  end
end
```

Obviously, this example method doesn't benefit much from a caching approach: computation already needs to be done to achieve argument normalization and the actual logic for the method is quite lightweight. In most cases, methods that take arguments are usually not going to be good candidates for caching because the explosion problem may represent too big a risk for the benefits that caching would provide, but there may be circumstances where it is advantageous, so it is supported.

## Other Advisories

### Redefining an enabled method

Redefining a method that Memorb has already overridden can be done. Since Memorb's override of the method is of greater precedence, Memorb will continue to work for the method. But if you are doing this, you'll want to read this section to understand what behavior to expect.

Any return values from previous executions of the method will remain in Memorb's cache even after the method has been redefined. If the method was redefined in a way that return values from the old definition no longer make sense for the application, then you can clear the cache after redefining the method.

If redefinining the method changes its class visibility, see the next section.

### Changing the visibility of an enabled method

If you change the visibility of an enabled method, Memorb won't automatically know that it needs to change the visibility of its corresponding override, so the visibility change will appear to have not worked because Memorb's override takes precedence. Memorb is unable to reliably override the visibility modifier for a class to detect such changes on its own (see [this Ruby not-a-bug report](https://bugs.ruby-lang.org/issues/16100)). You're advised to avoid doing this.

### Aliasing overridden methods

...

### Potential for initial method invocation race

If you are relying on Memorb's serialization for method invocation to prevent multiple executions of a method body across threads, then you should read this section.

Memorb overrides a registered method only once that method has been defined. To prevent `respond_to?` from returning true for an instance prematurely or allowing the method to be called prematurely, Memorb must wait until after the method is officially defined. There is no way to hook into Ruby's method definition process (in pure Ruby), so Memorb can only know of a method definition event after it has occurred using Ruby's provided notification methods.

This means that there is a small window of time between when a registered method is originally defined and when Memorb overrides it with memoization support. For methods that are registered and defined within the initial class definition, this shouldn't be a problem because there should be no instantiations of the class before its initial definition is closed. But methods that are defined dynamically may be able to be called by another thread before Memorb has had a chance to override them.
