module Memorb
  class Configurable < Module

    def initialize(*args)
      @args = args
      @methods = args
    end

    def included(base)
      super
      mixin = Mixin.mixin(base)
      @methods.each { |name| mixin.register(name) }
    end

    def inspect
      "#{ self.class.name }(#{ @args.map(&:inspect).join(', ') })"
    end

  end
end
