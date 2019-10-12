# frozen_string_literal: true

require_relative 'memorb/version'
require_relative 'memorb/ruby_compatibility'
require_relative 'memorb/errors'
require_relative 'memorb/method_identifier'
require_relative 'memorb/key_value_store'
require_relative 'memorb/integrator_class_methods'
require_relative 'memorb/integration'
require_relative 'memorb/agent'

module Memorb
  class << self

    def extended(base)
      Integration.integrate_with!(base)
    end

    def included(*)
      _raise_invalid_integration_error!
    end

    def prepended(*)
      _raise_invalid_integration_error!
    end

    private

    def _raise_invalid_integration_error!
      raise InvalidIntegrationError
        .new('Memorb must be integrated using `extend`')
    end

  end
end
