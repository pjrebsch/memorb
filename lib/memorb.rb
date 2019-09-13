# frozen_string_literal: true

require_relative 'memorb/version'
require_relative 'memorb/errors'
require_relative 'memorb/method_identifier'
require_relative 'memorb/key_value_store'
require_relative 'memorb/integrator_class_methods'
require_relative 'memorb/integration'
require_relative 'memorb/cache'

module Memorb
  class << self

    def extended(base)
      Integration.integrate_with!(base)
    end

  end
end

def Memorb(&block)
  target = block.binding.receiver
  integration = ::Memorb::Integration.integrate_with!(target)
  integration.register(&block)
  ::Memorb
end
