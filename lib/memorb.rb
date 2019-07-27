require_relative 'memorb/errors'
require_relative 'memorb/key_value_store'
require_relative 'memorb/integrator_class_methods'
require_relative 'memorb/integration'
require_relative 'memorb/cache'
require_relative 'memorb/configurable'

module Memorb
  class << self

    def [](*args)
      Configurable.new(*args)
    end

    def included(base)
      Integration.integrate_with!(base)
    end

    alias_method :prepended, :included

  end
end

def Memorb(*args)
  Memorb::Configurable.new(*args)
end
