require_relative 'memorb/core'
require_relative 'memorb/class_methods'
require_relative 'memorb/instance_methods'

module Memorb
  class << self

    def [](*methods)
      Core.generate_mixin(methods)
    end

  end
end
