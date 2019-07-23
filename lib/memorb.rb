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
      integrate! base
    end

    alias_method :prepended, :included

    @@integrations = KeyValueStore.new

    def integrate!(integrator)
      @@integrations.fetch(integrator) do
        Integration.new(integrator).tap do |integration|
          integrator.extend IntegratorClassMethods
          integrator.prepend integration
        end
      end
    end

    def integration(integrator)
      @@integrations.read(integrator)
    end

  end
end

def Memorb(*args)
  Memorb::Configurable.new(*args)
end
