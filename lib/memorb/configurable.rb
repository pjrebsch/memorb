module Memorb
  class Configurable < Module

    def self.[](*args)
      new(*args)
    end

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
      "#{ self.class.name }#{ @args.inspect }"
    end

    def register!(base)
      integration = Memorb.integrate!(base)
      @methods.each { |name| integration.register(name) }
    end

  end
end
