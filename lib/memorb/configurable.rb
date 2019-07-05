module Memorb
  class Configurable < Module

    def included(base)
      super
      @integration = base
      mixin = Mixin.mixin(base)
      @methods.each { |name| mixin.register(name) }
    end

    def initialize(*args)
      @integration = nil
      @args = args
      @methods = args
    end

    def inspect
      "#{ self.class.name }(#{ @args.map(&:inspect).join(', ') })"
    end

  end
end
