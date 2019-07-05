module Memorb
  class Configurable < Module

    def initialize(*args)
      @args = args
      @methods = args
    end

    def included(base)
      super
      register!(base)
    end

    def prepended(base)
      super
      register!(base)
    end

    def inspect
      "#{ self.class.name }[#{ @args.map(&:inspect).join(', ') }]"
    end

    def register!(base)
      mixin = Mixin.mixin!(base)
      @methods.each { |name| mixin.register(name) }
    end

  end
end
