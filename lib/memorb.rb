require_relative 'memorb/version'
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

    def extended(base)
      Integration.integrate_with!(base)
    end

  end
end

def Memorb(*args)
  Memorb::Configurable.new(*args)
end
