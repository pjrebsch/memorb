require_relative 'memorb/class_methods'
require_relative 'memorb/mixin'

module Memorb

  class << self
    def [](*methods)
      self
    end

    def included(base)
      Mixin.mixin(base)
    end
  end

end
