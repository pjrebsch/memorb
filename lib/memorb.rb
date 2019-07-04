require_relative 'memorb/core'
require_relative 'memorb/class_methods'
require_relative 'memorb/mixin'

module Memorb

  class << self
    def [](*methods)
      self
    end

    def included(base)
      Core.inclusion_procedure(base)
    end
  end

end
