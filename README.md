# Memorb

Memoize instance methods with ease.

[![CircleCI](https://circleci.com/gh/pjrebsch/memorb/tree/master.svg?style=svg)](https://circleci.com/gh/pjrebsch/memorb/tree/master)

## Overview

Specifying methods to be memoized by Memorb is referred to as "registering" them. When a method is registered and defined, Memorb will override it so that on initial invocation, the method's return value is cached to be returned immediately on every invocation thereafter. Once the method has been overridden, it is considered "enabled" for Memorb functionality. Internally, calls to the overriding method implementation are serialized with a read-write lock to guarantee that the initial method call is not subject to a race condition between threads, while also optimizing the performance of concurrent reads of the cached result.

Below is a contrived example class that could benefit from memoization. It is designed for effective demonstration, not for making a good case for the use of memoization.

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

## Usage

### Class Methods

#### `register` / `memorb!`

Use this method to register instance methods for memoization. Such methods will be enabled (overridden) with the memoization features once they are both registered and defined.

Registration of methods tells Memorb to enable memoization for them once they are defined. There are a few ways to register instance methods with Memorb. A common requirement is that a class must integrate Memorb with `extend Memorb` except for classes that inherit from a class that already has. Registration can be done with `memorb.register` or `memorb!` from a class context. It is recommended in general that you register methods before defining them.

##### List form

This is the form used in the example code snippet above where Memorb is given a list of method names to register. The provided names may be strings or symbols.

Memorb can't know when a registered method's definition is going to occur, so if you mistype the name of a method you intend to define later, Memorb will anticipate that method's definition indefinitely and the method that you intended to register won't end up being memoized. For this reason (among others), the Prefix form described below is recommended.

If you do use the List form, you can check that all registered methods were enabled by checking that `::disabled_methods` is empty which might be valuable in a test suite.

##### Prefix form

Conveniently, methods defined using the `def` keyword return the method name, so the method definition can just be prefixed with a registration directive. This approach helps make apparent the fact that the method is being memoized when reading the method.

```ruby
class WeekForecast
  extend Memorb
  memorb! def week_days
    ...
  end
end
```

If you prefer `def` and `end` to align, you can move `memorb!` up to a new line and escape the line break. The Memorb registration methods require arguments, so if you forget to escape the line break, you'll be made aware when the class is loaded.

```ruby
memorb! \
def week_days
  ...
end
```

##### Block form

Instead of listing out method names or decorating their definitions, you can just define them within a block.

```ruby
class WeekForecast
  extend Memorb
  ...
  memorb! do
    def data
      ...
    end
    def week_days
      ...
    end
    def rain_on?(day)
      ...
    end
    def will_rain?
      ...
    end
  end
end
```

Just be careful not to accidentally include any other methods that must always execute!

It is also important to note that all instance methods that are defined while the block is executing will be registered, not just the ones that can be seen using the `def` keyword. This is also not thread-safe, so if you are defining methods concurrently (which you shouldn't be), you may risk registering methods you didn't intend to register.

#### `registered_methods`

Returns the names of methods that have been registered for the integrating class.

#### `registered?(method_name)`

Returns whether or not the specified method is registered.

#### `enable(method_name)` / `disable(method_name)`

Enable/Disable a registered method.

#### `enabled?(method_name)`

Returns whether or not the specified method is enabled.

#### `enabled_methods` / `disabled_methods`

Returns which methods are enabled/disabled for the integrating class.

#### `purge(method_name)`

Clears all caches for the specified method across all instances of the integrating class.

### Instance Methods

#### `memorb`

Returns the Memorb agent for the object instance.

## Advisories

### Cache Explosion

No, sorry, not [the show](https://www.cashexplosionshow.com/).

Because memoization trades computation for memory, there is potential for memory explosion with a method that accepts arguments. All distinct sets of arguments to a method will map to a return value, and this mapping will be stored, so the potential for explosion increases exponentially as more arguments are supported. As long as the method is guaranteed to be called with a small, finite set of arguments, this needn't be much of a concern. But if the method is expected to handle arbitrary arguments or a large range of values, you may want to handle caching at a lower level within the method or even abandon the memoization/caching approach altogether.

The `rain_on?` method in the example class represents a method that is subject to this. It can also be used as an example of how to handle caching at a lower level. The only valid arguments to it are a representation of the seven days of the week, so there need only ever be up to seven cache entries. The day might not always be passed as a string—it could be anything that responds to `to_s`. The logic of the method doesn't care because it always transforms the argument to a string, but Memorb can't know what values for that argument the method's logic would consider to be the same thing, so it would cache them as distinct values. A solution is to perform "argument normalization" and use the results of that to implement caching within the method:

```ruby
def rain_on?(day)
  day = day.to_s
  return unless week_days.include?(day)
  memorb.fetch([__method__, day]) do
    ...
  end
end
```

Obviously, this method doesn't benefit much from a caching approach in the first place: computation already needs to be done to achieve argument normalization and the actual logic for the method is quite lightweight. Methods that take arguments may not be good candidates for memoization because the explosion problem may represent too big a risk for the benefits that caching would provide, but this is a judgment call to be made per case.

### Blocks are not considered distinguishing arguments

Memorb ignores block arguments when determining whether or not a method has been called with the same arguments. It doesn't matter if a block is provided explicitly (using `&block` as a parameter), provided implicitly (using `yield` in the method body), or not provided at all. Therefore, blocks should not be used to distinguish otherwise equivalent method calls for the sake of memoization.

However, a `Proc` can be passed as a normal argument and it _will_ be used in distinguishing method calls.

### Redefining an enabled method

Redefining a method that Memorb has already overridden can be done. Since Memorb's override of the method is of greater precedence, Memorb will continue to work for the method. But if you are doing this, you'll want to read this section to understand what behavior to expect.

Any return values from previous executions of the method will remain in Memorb's cache even after the method has been redefined. If the method was redefined in a way that return values from the old definition no longer make sense for the application, then you can clear the cache after redefining the method.

If redefinining the method changes its class visibility, see the next section.

### Changing the visibility of an enabled method

If you change the visibility of an enabled method, Memorb won't automatically know that it needs to change the visibility of its corresponding override, so the visibility change will appear to have not worked because Memorb's override takes precedence. Memorb is unable to reliably override the visibility modifier for a class to detect such changes on its own (see [this Ruby not-a-bug report](https://bugs.ruby-lang.org/issues/16100)). You're advised to avoid doing this.

### Aliasing overridden methods

Using `alias_method` in Ruby will create a copy under the new name of the existing method implementation found at that time. This means that the aliased method will have different behavior relative to when the method was overridden by Memorb. If the method was aliased before override by Memorb, then it's calls will not reference the cache of the original method, but if aliased after the override, then it will.

### Alias method chaining on overridden methods

If you or another library uses alias method chaining on a method that Memorb has overridden, you will experience infinite recursion upon calling that method. See [this article](https://blog.newrelic.com/engineering/ruby-agent-module-prepend-alias-method-chains/) for an explanation of the incompatibility between using `Module#prepend` (which Memorb uses internally) with the alias method chaining technique. Refactoring such alias method chaining in the integrating class to instead use `Module#prepend` will prevent this issue.

### Potential for initial method invocation race

If you are relying on Memorb's serialization for method invocation to prevent multiple executions of a method body across threads, then you should read this section.

Memorb overrides a registered method only once that method has been defined. To prevent `respond_to?` from returning true for an instance prematurely or allowing the method to be called prematurely, Memorb must wait until after the method is officially defined. There is no way to hook into Ruby's method definition process (in pure Ruby), so Memorb can only know of a method definition event after it has occurred using Ruby's provided notification methods.

This means that there is a small window of time between when a registered method is originally defined and when Memorb overrides it with memoization support. For methods that are registered and defined within the initial class definition, this shouldn't be a problem because there should be no instantiations of the class before its initial definition is closed. But methods that are defined dynamically may be able to be called by another thread before Memorb has had a chance to override them.

## Potential Enhancements

### Ability to configure Memorb

It could be beneficial to configure Memorb, though the options for configuration are unclear.

### Ability to log cache accesses

Caching introduces the possibility of bugs when things are cached too much. It would be helpful for debugging to be able to configure a `Logger` for cache accesses.

### Alternative to instance variables

Expanding Memorb to more than just memoization could include providing enhanced features for local instance state, such as capturing parameters during `initialize`.
